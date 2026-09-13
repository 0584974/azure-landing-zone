#!/bin/bash

# Azure Landing Zone - EU Deployment Script
# Comprehensive deployment script for Azure Landing Zone infrastructure
# This script replaces Azure DevOps pipeline functionality with manual deployment

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +"%d%m%Y%H%M%S")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="$SCRIPT_DIR/variables.json"

# Configuration variables (loaded from variables.json, can be overridden by command line)
ENVIRONMENT=""
REGION=""
DEPLOYMENT_LOCATION=""
MANAGEMENT_GROUP_ID=""
TOP_LEVEL_MG_PREFIX=""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to authenticate to Azure
authenticate_azure() {
    print_step "Handling Azure authentication..."
    
    # Load authentication configuration from variables.json
    local auth_method=""
    local tenant_id=""
    local sp_id=""
    local sp_secret=""
    local default_subscription=""
    
    if [ -f "$VARIABLES_FILE" ]; then
        auth_method=$(jq -r '.parameters.authenticationConfiguration.method.value' "$VARIABLES_FILE" 2>/dev/null)
        tenant_id=$(jq -r '.parameters.authenticationConfiguration.tenantId.value' "$VARIABLES_FILE" 2>/dev/null)
        sp_id=$(jq -r '.parameters.authenticationConfiguration.servicePrincipalId.value' "$VARIABLES_FILE" 2>/dev/null)
        sp_secret=$(jq -r '.parameters.authenticationConfiguration.servicePrincipalSecret.value' "$VARIABLES_FILE" 2>/dev/null)
        default_subscription=$(jq -r '.parameters.authenticationConfiguration.subscriptionId.value' "$VARIABLES_FILE" 2>/dev/null)
    fi
    
    # Set defaults if values are null or empty
    [ "$auth_method" = "null" ] || [ -z "$auth_method" ] && auth_method="interactive"
    [ "$tenant_id" = "null" ] && tenant_id=""
    [ "$sp_id" = "null" ] && sp_id=""
    [ "$sp_secret" = "null" ] && sp_secret=""
    [ "$default_subscription" = "null" ] && default_subscription=""
    
    # Check if already logged in
    if az account show &> /dev/null; then
        print_status "Already authenticated to Azure"
        local current_user=$(az account show --query "user.name" -o tsv 2>/dev/null)
        local current_subscription=$(az account show --query "name" -o tsv 2>/dev/null)
        print_status "Current user: $current_user"
        print_status "Current subscription: $current_subscription"
        return 0
    fi
    
    print_status "Authentication method: $auth_method"
    
    case "$auth_method" in
        "interactive")
            print_status "Using interactive login..."
            if [ -n "$tenant_id" ]; then
                az login --tenant "$tenant_id"
            else
                az login
            fi
            ;;
        "service-principal")
            if [ -z "$tenant_id" ] || [ -z "$sp_id" ]; then
                print_error "Service principal authentication requires tenantId and servicePrincipalId in variables.json"
                exit 1
            fi
            
            # Check for secret in environment variable first
            if [ -n "$AZURE_CLIENT_SECRET" ]; then
                sp_secret="$AZURE_CLIENT_SECRET"
            elif [ -n "$ARM_CLIENT_SECRET" ]; then
                sp_secret="$ARM_CLIENT_SECRET"
            elif [ -z "$sp_secret" ]; then
                print_error "Service principal secret not found. Set AZURE_CLIENT_SECRET environment variable or configure servicePrincipalSecret in variables.json"
                exit 1
            fi
            
            print_status "Using service principal authentication..."
            az login --service-principal --username "$sp_id" --password "$sp_secret" --tenant "$tenant_id"
            ;;
        "managed-identity")
            print_status "Using managed identity authentication..."
            az login --identity
            ;;
        "device-code")
            print_status "Using device code authentication..."
            if [ -n "$tenant_id" ]; then
                az login --use-device-code --tenant "$tenant_id"
            else
                az login --use-device-code
            fi
            ;;
        *)
            print_error "Unknown authentication method: $auth_method"
            print_error "Supported methods: interactive, service-principal, managed-identity, device-code"
            exit 1
            ;;
    esac
    
    # Set default subscription if specified
    if [ -n "$default_subscription" ]; then
        print_status "Setting default subscription: $default_subscription"
        az account set --subscription "$default_subscription"
    fi
    
    # Verify authentication was successful
    if ! az account show &> /dev/null; then
        print_error "Authentication failed"
        exit 1
    fi
    
    local authenticated_user=$(az account show --query "user.name" -o tsv)
    local current_subscription=$(az account show --query "name" -o tsv)
    print_status "Successfully authenticated as: $authenticated_user"
    print_status "Current subscription: $current_subscription"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI version 2.40.0 or newer."
        exit 1
    fi
    
    # Check Azure CLI version
    AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
    print_status "Azure CLI version: $AZ_VERSION"
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. Some features may not work properly."
        print_status "Install jq with: sudo apt-get install jq (Ubuntu) or brew install jq (macOS)"
    fi
    
    print_status "Prerequisites check completed."
}

# Function to load configuration from variables.json
load_configuration() {
    print_step "Loading configuration from variables.json..."
    
    if [ ! -f "$VARIABLES_FILE" ]; then
        print_error "Variables file not found: $VARIABLES_FILE"
        exit 1
    fi
    
    # Load configuration values from variables.json (only if not already set by command line)
    if [ -z "$DEPLOYMENT_LOCATION" ]; then
        DEPLOYMENT_LOCATION=$(jq -r '.parameters.deploymentConfiguration.primaryLocation.value' "$VARIABLES_FILE")
        if [ "$DEPLOYMENT_LOCATION" = "null" ] || [ -z "$DEPLOYMENT_LOCATION" ]; then
            DEPLOYMENT_LOCATION="swedencentral"  # Final fallback
            print_warning "Primary location not found in variables.json, using fallback: $DEPLOYMENT_LOCATION"
        fi
    fi
    
    if [ -z "$MANAGEMENT_GROUP_ID" ]; then
        MANAGEMENT_GROUP_ID=$(jq -r '.parameters.deploymentConfiguration.managementGroupId.value' "$VARIABLES_FILE")
        if [ "$MANAGEMENT_GROUP_ID" = "null" ] || [ -z "$MANAGEMENT_GROUP_ID" ]; then
            MANAGEMENT_GROUP_ID="alz"  # Final fallback
            print_warning "Management Group ID not found in variables.json, using fallback: $MANAGEMENT_GROUP_ID"
        fi
    fi
    
    if [ -z "$TOP_LEVEL_MG_PREFIX" ]; then
        TOP_LEVEL_MG_PREFIX=$(jq -r '.parameters.deploymentConfiguration.topLevelManagementGroupPrefix.value' "$VARIABLES_FILE")
        if [ "$TOP_LEVEL_MG_PREFIX" = "null" ] || [ -z "$TOP_LEVEL_MG_PREFIX" ]; then
            TOP_LEVEL_MG_PREFIX="alz"  # Final fallback
            print_warning "Management Group Prefix not found in variables.json, using fallback: $TOP_LEVEL_MG_PREFIX"
        fi
    fi
    
    # Load ENVIRONMENT and REGION from variables.json if not provided via command line
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT=$(jq -r '.parameters.deploymentConfiguration.environment.value' "$VARIABLES_FILE")
        if [ "$ENVIRONMENT" = "null" ] || [ -z "$ENVIRONMENT" ]; then
            ENVIRONMENT="Prod"  # Final fallback
            print_warning "Environment not found in variables.json, using fallback: $ENVIRONMENT"
        fi
    fi
    
    if [ -z "$REGION" ]; then
        REGION=$(jq -r '.parameters.deploymentConfiguration.region.value' "$VARIABLES_FILE")
        if [ "$REGION" = "null" ] || [ -z "$REGION" ]; then
            REGION="SwedenCentral"  # Final fallback
            print_warning "Region not found in variables.json, using fallback: $REGION"
        fi
    fi
    
    print_status "Configuration loaded:"
    print_status "  Primary Location: $DEPLOYMENT_LOCATION"
    print_status "  Management Group ID: $MANAGEMENT_GROUP_ID"
    print_status "  Management Group Prefix: $TOP_LEVEL_MG_PREFIX"
    print_status "  Environment (for parsing): $ENVIRONMENT"
    print_status "  Region (for parsing): $REGION"
}

# Function to parse subscription IDs
parse_subscription_ids() {
    print_step "Parsing subscription IDs..."
    
    # Try automatic parsing first if subscriptions follow naming convention
    print_status "Attempting automatic subscription parsing using naming convention..."
    
    MANAGEMENT_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Management-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    CONNECTIVITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Connectivity-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    IDENTITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Identity-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    SECURITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Security-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    LOGGING_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Logging-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    PLATFORM_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Platform-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    LANDINGZONE_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-LandingZone-${ENVIRONMENT}-${REGION}')].id" --output tsv 2>/dev/null || echo "")
    
    # Check if automatic parsing was successful
    if [[ -z "$MANAGEMENT_SUB" || -z "$CONNECTIVITY_SUB" || -z "$IDENTITY_SUB" || -z "$SECURITY_SUB" || -z "$LOGGING_SUB" || -z "$PLATFORM_SUB" || -z "$LANDINGZONE_SUB" ]]; then
        print_warning "Automatic parsing failed. Loading from variables.json..."
        
        # Load from variables.json
        MANAGEMENT_SUB=$(jq -r '.parameters.subscriptionIds.management.value' "$VARIABLES_FILE")
        CONNECTIVITY_SUB=$(jq -r '.parameters.subscriptionIds.connectivity.value' "$VARIABLES_FILE")
        IDENTITY_SUB=$(jq -r '.parameters.subscriptionIds.identity.value' "$VARIABLES_FILE")
        SECURITY_SUB=$(jq -r '.parameters.subscriptionIds.security.value' "$VARIABLES_FILE")
        LOGGING_SUB=$(jq -r '.parameters.subscriptionIds.logging.value' "$VARIABLES_FILE")
        PLATFORM_SUB=$(jq -r '.parameters.subscriptionIds.platform.value' "$VARIABLES_FILE")
        LANDINGZONE_SUB=$(jq -r '.parameters.subscriptionIds.landingZone.value' "$VARIABLES_FILE")
    else
        print_status "Successfully parsed subscription IDs from naming convention"
        
        # Update variables.json with parsed subscription IDs
        if command -v jq &> /dev/null; then
            print_status "Updating variables.json with parsed subscription IDs..."
            jq --arg mgmt "$MANAGEMENT_SUB" \
               --arg conn "$CONNECTIVITY_SUB" \
               --arg id "$IDENTITY_SUB" \
               --arg sec "$SECURITY_SUB" \
               --arg log "$LOGGING_SUB" \
               --arg plat "$PLATFORM_SUB" \
               --arg lz "$LANDINGZONE_SUB" \
               '.parameters.subscriptionIds.management.value = $mgmt |
                .parameters.subscriptionIds.connectivity.value = $conn |
                .parameters.subscriptionIds.identity.value = $id |
                .parameters.subscriptionIds.security.value = $sec |
                .parameters.subscriptionIds.logging.value = $log |
                .parameters.subscriptionIds.platform.value = $plat |
                .parameters.subscriptionIds.landingZone.value = $lz' \
               "$VARIABLES_FILE" > "${VARIABLES_FILE}.tmp" && mv "${VARIABLES_FILE}.tmp" "$VARIABLES_FILE"
        fi
    fi
    
    # Display subscription IDs
    print_status "Subscription IDs:"
    print_status "  Management:    $MANAGEMENT_SUB"
    print_status "  Connectivity:  $CONNECTIVITY_SUB"
    print_status "  Identity:      $IDENTITY_SUB"
    print_status "  Security:      $SECURITY_SUB"
    print_status "  Logging:       $LOGGING_SUB"
    print_status "  Platform:      $PLATFORM_SUB"
    print_status "  Landing Zone:  $LANDINGZONE_SUB"
    
    # Validate subscription IDs
    if [[ -z "$MANAGEMENT_SUB" || -z "$CONNECTIVITY_SUB" || -z "$IDENTITY_SUB" || -z "$SECURITY_SUB" || -z "$LOGGING_SUB" || -z "$PLATFORM_SUB" || -z "$LANDINGZONE_SUB" ]]; then
        print_error "One or more subscription IDs are missing. Please update variables.json with actual subscription IDs."
        exit 1
    fi
    
    # Check if subscription IDs are still placeholder values
    local placeholder_pattern="^00000000-0000-0000-0000-00000000000[0-9]$"
    if [[ "$MANAGEMENT_SUB" =~ $placeholder_pattern ]] || \
       [[ "$CONNECTIVITY_SUB" =~ $placeholder_pattern ]] || \
       [[ "$IDENTITY_SUB" =~ $placeholder_pattern ]] || \
       [[ "$SECURITY_SUB" =~ $placeholder_pattern ]] || \
       [[ "$LOGGING_SUB" =~ $placeholder_pattern ]] || \
       [[ "$PLATFORM_SUB" =~ $placeholder_pattern ]] || \
       [[ "$LANDINGZONE_SUB" =~ $placeholder_pattern ]]; then
        print_error "Subscription IDs appear to be placeholder values. Please update variables.json with actual subscription IDs."
        print_error "Placeholder pattern detected: 00000000-0000-0000-0000-00000000000X"
        exit 1
    fi
}

# Function to process variable substitution
process_variable_substitution() {
    print_step "Processing variable substitution..."
    
    # Load additional variables from variables.json
    LOGGING_RG=$(jq -r '.parameters.resourceGroupNames.logging.value' "$VARIABLES_FILE")
    CONNECTIVITY_RG=$(jq -r '.parameters.resourceGroupNames.connectivity.value' "$VARIABLES_FILE")
    LOG_ANALYTICS_NAME=$(jq -r '.parameters.resourceNames.logAnalyticsWorkspace.value' "$VARIABLES_FILE")
    
    # Validate loaded variables
    if [ "$LOGGING_RG" = "null" ] || [ -z "$LOGGING_RG" ]; then
        print_error "Failed to load logging resource group name from variables.json"
        exit 1
    fi
    if [ "$CONNECTIVITY_RG" = "null" ] || [ -z "$CONNECTIVITY_RG" ]; then
        print_error "Failed to load connectivity resource group name from variables.json"
        exit 1
    fi
    if [ "$LOG_ANALYTICS_NAME" = "null" ] || [ -z "$LOG_ANALYTICS_NAME" ]; then
        print_error "Failed to load Log Analytics workspace name from variables.json"
        exit 1
    fi
    
    # Process all files with variable substitution
    find "$SCRIPT_DIR" -name "*.json" -o -name "*.bicep" | while read file; do
        # Skip the variables.json file itself
        if [[ "$file" == "$VARIABLES_FILE" ]]; then
            continue
        fi
        
        # Create backup
        cp "$file" "${file}.backup"
        
        # Process subscription IDs
        sed -i.tmp "s/{{subscriptionIds\.management\.value}}/$MANAGEMENT_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.connectivity\.value}}/$CONNECTIVITY_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.identity\.value}}/$IDENTITY_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.security\.value}}/$SECURITY_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.logging\.value}}/$LOGGING_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.platform\.value}}/$PLATFORM_SUB/g" "$file"
        sed -i.tmp "s/{{subscriptionIds\.landingZone\.value}}/$LANDINGZONE_SUB/g" "$file"
        
        # Process deployment configuration
        sed -i.tmp "s/{{deploymentConfiguration\.primaryLocation\.value}}/$DEPLOYMENT_LOCATION/g" "$file"
        sed -i.tmp "s/{{deploymentConfiguration\.managementGroupId\.value}}/$MANAGEMENT_GROUP_ID/g" "$file"
        sed -i.tmp "s/{{deploymentConfiguration\.topLevelManagementGroupPrefix\.value}}/$TOP_LEVEL_MG_PREFIX/g" "$file"
        
        # Process resource names
        sed -i.tmp "s/{{resourceGroupNames\.logging\.value}}/$LOGGING_RG/g" "$file"
        sed -i.tmp "s/{{resourceGroupNames\.connectivity\.value}}/$CONNECTIVITY_RG/g" "$file"
        sed -i.tmp "s/{{resourceNames\.logAnalyticsWorkspace\.value}}/$LOG_ANALYTICS_NAME/g" "$file"
        
        # Remove temporary files
        rm -f "${file}.tmp"
    done
    
    print_status "Variable substitution completed."
}

# Function to deploy management groups
deploy_management_groups() {
    print_step "Deploying Management Groups..."
    
    az deployment tenant create \
        --name "alz-MGDeployment-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --template-file "./infra-as-code/bicep/modules/managementGroups/managementGroups.bicep" \
        --parameters "./infra-as-code/bicep/modules/managementGroups/parameters/managementGroups.parameters.all.json"
    
    print_status "Management Groups deployment completed."
}

# Function to deploy custom policy definitions
deploy_custom_policy_definitions() {
    print_step "Deploying Custom Policy Definitions..."
    
    az deployment mg create \
        --name "alz-PolicyDefsDefaults-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/modules/policy/definitions/customPolicyDefinitions.bicep" \
        --parameters "./infra-as-code/bicep/modules/policy/definitions/parameters/customPolicyDefinitions.parameters.all.json"
    
    print_status "Custom Policy Definitions deployment completed."
}

# Function to deploy custom role definitions
deploy_custom_role_definitions() {
    print_step "Deploying Custom Role Definitions..."
    
    az deployment mg create \
        --name "alz-CustomRoleDefsDeployment-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep" \
        --parameters "./infra-as-code/bicep/modules/customRoleDefinitions/parameters/customRoleDefinitions.parameters.all.json"
    
    print_status "Custom Role Definitions deployment completed."
}

# Function to deploy logging infrastructure
deploy_logging() {
    print_step "Deploying Logging Infrastructure..."
    
    LOGGING_RG=$(jq -r '.parameters.resourceGroupNames.logging.value' "$VARIABLES_FILE")
    
    az deployment sub create \
        --name "alz-loggingDeployment-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --subscription "$MANAGEMENT_SUB" \
        --template-file "./infra-as-code/bicep/modules/logging/logging.bicep" \
        --parameters "./infra-as-code/bicep/modules/logging/parameters/logging.parameters.all.json"
    
    print_status "Logging Infrastructure deployment completed."
}

# Function to deploy hub networking
deploy_hub_networking() {
    print_step "Deploying Hub Networking..."
    
    CONNECTIVITY_RG=$(jq -r '.parameters.resourceGroupNames.connectivity.value' "$VARIABLES_FILE")
    
    az deployment sub create \
        --name "alz-HubNetworkingDeploy-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --subscription "$CONNECTIVITY_SUB" \
        --template-file "./infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep" \
        --parameters "./infra-as-code/bicep/modules/hubNetworking/parameters/hubNetworking.parameters.all.json"
    
    print_status "Hub Networking deployment completed."
}

# Function to deploy management group diagnostic settings
deploy_mg_diagnostic_settings() {
    print_step "Deploying Management Group Diagnostic Settings..."
    
    az deployment mg create \
        --name "alz-MgDiagSettingsDeployment-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep" \
        --parameters "./infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.all.json"
    
    print_status "Management Group Diagnostic Settings deployment completed."
}

# Function to deploy subscription placement
deploy_subscription_placement() {
    print_step "Deploying Subscription Placement..."
    
    az deployment mg create \
        --name "alz-SubPlacementAll-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/orchestration/subPlacementAll/subPlacementAll.bicep" \
        --parameters "./infra-as-code/bicep/orchestration/subPlacementAll/parameters/subPlacementAll.parameters.all.json"
    
    print_status "Subscription Placement deployment completed."
}

# Function to deploy default policy assignments
deploy_default_policy_assignments() {
    print_step "Deploying Default Policy Assignments..."
    
    az deployment mg create \
        --name "alz-alzPolicyAssignmentDefaults-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.bicep" \
        --parameters "./infra-as-code/bicep/modules/policy/assignments/alzDefaults/parameters/alzDefaultPolicyAssignments.parameters.all.json"
    
    print_status "Default Policy Assignments deployment completed."
}

# Function to deploy custom policy assignments
deploy_custom_policy_assignments() {
    print_step "Deploying Custom Policy Assignments..."
    
    az deployment mg create \
        --name "alz-alzPolicyAssignmentCustom-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./policies/alzCustomPolicyAssignments.bicep"
    
    print_status "Custom Policy Assignments deployment completed."
}

# Function to deploy role assignments
deploy_role_assignments() {
    print_step "Deploying Role Assignments..."
    
    az deployment mg create \
        --name "alz-NetworkManagerRoleAssignmentsDeployment-${TIMESTAMP}" \
        --location "$DEPLOYMENT_LOCATION" \
        --management-group-id "$MANAGEMENT_GROUP_ID" \
        --template-file "./infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep" \
        --parameters "./infra-as-code/bicep/modules/roleAssignments/parameters/roleAssignmentManagementGroup.securityGroup.parameters.all.json"
    
    print_status "Role Assignments deployment completed."
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [STEPS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                    Show this help message"
    echo "  -e, --environment ENV         Set environment for subscription parsing (default: from variables.json or 'Prod')"
    echo "  -r, --region REGION           Set region for subscription parsing (default: from variables.json or 'SwedenCentral')"
    echo "  -l, --location LOCATION       Set deployment location (default: from variables.json or 'swedencentral')"
    echo "  -m, --management-group ID     Set management group ID (default: from variables.json or 'alz')"
    echo "  --dry-run                     Show what would be deployed without executing"
    echo "  --skip-prereq                 Skip prerequisites check"
    echo "  --skip-auth                   Skip Azure authentication (assume already authenticated)"
    echo "  --skip-variable-processing    Skip variable substitution processing"
    echo "  --auth-method METHOD          Override authentication method (interactive, service-principal, managed-identity, device-code)"
    echo ""
    echo "Configuration Priority (highest to lowest):"
    echo "  1. Command line arguments"
    echo "  2. Values from variables.json file"
    echo "  3. Built-in fallback defaults"
    echo ""
    echo "Steps (if none specified, all steps will be executed):"
    echo "  --management-groups           Deploy management groups"
    echo "  --policy-definitions          Deploy custom policy definitions"
    echo "  --role-definitions            Deploy custom role definitions"
    echo "  --logging                     Deploy logging infrastructure"
    echo "  --hub-networking              Deploy hub networking"
    echo "  --mg-diagnostic-settings      Deploy management group diagnostic settings"
    echo "  --subscription-placement      Deploy subscription placement"
    echo "  --default-policy-assignments  Deploy default policy assignments"
    echo "  --custom-policy-assignments   Deploy custom policy assignments"
    echo "  --role-assignments            Deploy role assignments"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Deploy everything using variables.json configuration"
    echo "  $0 --management-groups --policy-definitions # Deploy only management groups and policy definitions"
    echo "  $0 --dry-run                                # Show what would be deployed using variables.json"
    echo "  $0 -e Dev -r GermanyWestCentral             # Override environment and region from variables.json"
    echo "  $0 -l northeurope -m custom-mg              # Override location and management group from variables.json"
}

# Function to restore backups
restore_backups() {
    print_step "Restoring file backups..."
    find "$SCRIPT_DIR" -name "*.backup" | while read backup_file; do
        original_file="${backup_file%.backup}"
        if [ -f "$backup_file" ]; then
            mv "$backup_file" "$original_file"
            print_status "Restored: $original_file"
        fi
    done
}

# Function to clean up backups
cleanup_backups() {
    print_step "Cleaning up backup files..."
    find "$SCRIPT_DIR" -name "*.backup" -delete
    print_status "Backup files cleaned up."
}

# Main deployment function
main() {
    local steps_to_run=()
    local dry_run=false
    local skip_prereq=false
    local skip_auth=false
    local skip_variable_processing=false
    local auth_method_override=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -l|--location)
                DEPLOYMENT_LOCATION="$2"
                shift 2
                ;;
            -m|--management-group)
                MANAGEMENT_GROUP_ID="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --skip-prereq)
                skip_prereq=true
                shift
                ;;
            --skip-auth)
                skip_auth=true
                shift
                ;;
            --skip-variable-processing)
                skip_variable_processing=true
                shift
                ;;
            --auth-method)
                auth_method_override="$2"
                shift 2
                ;;
            --management-groups)
                steps_to_run+=("management_groups")
                shift
                ;;
            --policy-definitions)
                steps_to_run+=("policy_definitions")
                shift
                ;;
            --role-definitions)
                steps_to_run+=("role_definitions")
                shift
                ;;
            --logging)
                steps_to_run+=("logging")
                shift
                ;;
            --hub-networking)
                steps_to_run+=("hub_networking")
                shift
                ;;
            --mg-diagnostic-settings)
                steps_to_run+=("mg_diagnostic_settings")
                shift
                ;;
            --subscription-placement)
                steps_to_run+=("subscription_placement")
                shift
                ;;
            --default-policy-assignments)
                steps_to_run+=("default_policy_assignments")
                shift
                ;;
            --custom-policy-assignments)
                steps_to_run+=("custom_policy_assignments")
                shift
                ;;
            --role-assignments)
                steps_to_run+=("role_assignments")
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # If no specific steps specified, run all steps
    if [ ${#steps_to_run[@]} -eq 0 ]; then
        steps_to_run=("management_groups" "policy_definitions" "role_definitions" "logging" "hub_networking" "mg_diagnostic_settings" "subscription_placement" "default_policy_assignments" "custom_policy_assignments" "role_assignments")
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Azure Landing Zone - EU Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check prerequisites
    if [ "$skip_prereq" = false ]; then
        check_prerequisites
    fi
    
    # Handle authentication
    if [ "$skip_auth" = false ]; then
        # Override auth method if specified via command line
        if [ -n "$auth_method_override" ]; then
            # Temporarily update the auth method in memory for this run
            if [ -f "$VARIABLES_FILE" ]; then
                print_status "Overriding authentication method to: $auth_method_override"
                # Create temporary variables file with overridden auth method
                jq --arg method "$auth_method_override" \
                   '.parameters.authenticationConfiguration.method.value = $method' \
                   "$VARIABLES_FILE" > "${VARIABLES_FILE}.tmp"
                mv "${VARIABLES_FILE}.tmp" "$VARIABLES_FILE"
            fi
        fi
        authenticate_azure
    fi
    
    # Load configuration
    load_configuration
    
    # Parse subscription IDs
    parse_subscription_ids
    
    # Process variable substitution
    if [ "$skip_variable_processing" = false ]; then
        process_variable_substitution
    fi
    
    if [ "$dry_run" = true ]; then
        print_status "DRY RUN MODE - No actual deployments will be executed"
        print_status "Steps that would be executed:"
        for step in "${steps_to_run[@]}"; do
            echo "  - $step"
        done
        exit 0
    fi
    
    # Execute deployment steps
    for step in "${steps_to_run[@]}"; do
        case $step in
            management_groups)
                deploy_management_groups
                ;;
            policy_definitions)
                deploy_custom_policy_definitions
                ;;
            role_definitions)
                deploy_custom_role_definitions
                ;;
            logging)
                deploy_logging
                ;;
            hub_networking)
                deploy_hub_networking
                ;;
            mg_diagnostic_settings)
                deploy_mg_diagnostic_settings
                ;;
            subscription_placement)
                deploy_subscription_placement
                ;;
            default_policy_assignments)
                deploy_default_policy_assignments
                ;;
            custom_policy_assignments)
                deploy_custom_policy_assignments
                ;;
            role_assignments)
                deploy_role_assignments
                ;;
        esac
    done
    
    # Clean up backups on successful completion
    cleanup_backups
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Set up trap to restore backups on script exit/error
trap 'restore_backups' EXIT

# Run main function with all arguments
main "$@" 