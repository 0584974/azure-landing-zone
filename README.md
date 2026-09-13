# Azure Landing Zone - RIT Deployment Template

Azure Landing Zone provides a comprehensive foundation for European Union deployments:
- **Management Groups**: Hierarchical organization for governance and policy management
- **Subscriptions**: Specialized logical constructs for different types of workloads (management, connectivity, identity, security, etc.)
- **Networking**: Hub-spoke architecture with centralized connectivity
- **Security**: Comprehensive security policies and monitoring
- **Logging**: Centralized logging and monitoring system
- **Governance**: Policy-based governance and compliance control for EU data residency
- **Data Residency**: All resources deployed in European Union Azure regions

## Prerequisites

Before deployment, ensure you have:
- **Azure CLI**: Version 2.40.0 or newer
- **PowerShell**: Version 7.0 or newer (optional)
- **jq**: For JSON processing (recommended)
- **Git**: For version control and repository management
- **Azure Subscriptions**: Existing subscriptions
- **Owner permissions**: On all target subscriptions
- **Management Group permissions**: At Tenant Root Management Group level

## Step-by-Step Deployment Guide

### Important: Variables Management System

This deployment uses a centralized variables management system to eliminate hardcoded values and improve maintainability:

#### Key Features:
- **Centralized Configuration**: All subscription IDs, locations, and configuration values are stored in `variables.json` file
- **Template Processing**: Variable placeholders (`{{variableName}}`) are replaced with actual values during deployment
- **Environment Flexibility**: Easy deployment to different environments by updating the variables file
- **Automated Deployment**: Comprehensive deployment script handles the entire process

#### Variable Categories:
- **Deployment Configuration**: Environment and region settings for subscription parsing, EU regions (Sweden Central, Germany West Central), management group IDs and naming
- **Authentication Configuration**: Azure authentication methods and credentials
- **Subscription IDs**: All Azure subscription identifiers
- **Resource Configuration**: Resource group names, resource names and settings
- **Policy Configuration**: Custom policy assignments and compliance settings for EU regulations

### Step 1: Environment Setup

#### 1.1 Repository Cloning
```bash
git clone <repository-url>
cd GOVEE
```

#### 1.2 Azure Authentication

The deployment script supports multiple authentication methods. Configure your preferred method in the `variables.json` file:

**Interactive Login (Default):**
```bash
# The script will automatically prompt for interactive login
./deploy-alz.sh
```

**Service Principal Authentication:**
```bash
# Set environment variables (recommended for security)
export AZURE_CLIENT_SECRET="your-service-principal-secret"
export AZURE_CLIENT_ID="your-service-principal-id"
export AZURE_TENANT_ID="your-tenant-id"

# Or configure in variables.json and run
./deploy-alz.sh
```

**Managed Identity (for Azure VMs/Container Instances):**
```bash
# Configure method in variables.json as "managed-identity"
./deploy-alz.sh
```

**Device Code Authentication:**
```bash
# Useful for environments without web browser
./deploy-alz.sh --auth-method device-code
```

**Manual Authentication:**
```bash
# If you prefer to handle authentication separately
az login
./deploy-alz.sh --skip-auth
```

#### 1.3 Install Required Tools
```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install jq

# For macOS (with Homebrew)
brew install jq

# For Windows (with Chocolatey)
choco install jq
```

### Step 2: Obtaining Subscription IDs

**Note**: Subscriptions are created outside of this deployment through a RIT ordering process through government cloud self-service portal. Name the ordered subscriptions as per recommended naming convention in Azure portal. You cannot deploy subscriptions automatically with this script.

#### 2.1 Recommended Subscription Naming Convention

To enable automatic parsing and identification during deployment, use the following naming convention for manually created subscriptions:

```
Format: ALZ-EU-{PURPOSE}-{ENVIRONMENT}-{REGION}

Examples for Production Environment:
- ALZ-EU-Management-Prod-SwedenCentral
- ALZ-EU-Connectivity-Prod-SwedenCentral  
- ALZ-EU-Identity-Prod-SwedenCentral
- ALZ-EU-Security-Prod-SwedenCentral
- ALZ-EU-Logging-Prod-SwedenCentral
- ALZ-EU-Platform-Prod-SwedenCentral
- ALZ-EU-LandingZone-Prod-SwedenCentral

Examples for Development Environment:
- ALZ-EU-Management-Dev-SwedenCentral
- ALZ-EU-Connectivity-Dev-SwedenCentral
- ALZ-EU-Identity-Dev-SwedenCentral
- ALZ-EU-Security-Dev-SwedenCentral
- ALZ-EU-Logging-Dev-SwedenCentral
- ALZ-EU-Platform-Dev-SwedenCentral
- ALZ-EU-LandingZone-Dev-SwedenCentral

Alternative Regions examples:
- ALZ-EU-Management-Prod-GermanyWestCentral
- ALZ-EU-Connectivity-Prod-WestEurope
- etc.
```

#### 2.2 Naming Convention Benefits
- **Automatic Parsing**: Scripts can automatically identify subscription types by parsing the name
- **Environment Separation**: Clear distinction between dev/test/prod environments
- **Regional Identification**: Easy identification of deployment regions
- **Compliance Tracking**: EU designation for EU data residency compliance
- **Consistent Structure**: Standardized naming across all subscriptions
- **Script Integration**: Deployment scripts can parse subscription purposes automatically

#### 2.3 Required Subscriptions
The following EU subscriptions must exist before deployment and their subscription IDs must be provided by your Azure administrator:

- **EU Management Subscription**: For Azure Landing Zone operations and management resources (EU regions only)
- **EU Connectivity Subscription**: For hub networking and connectivity resources (EU regions only)
- **EU Identity Subscription**: For identity management and Azure AD resources (EU regions only)
- **EU Security Subscription**: For security services and compliance resources (EU regions only)
- **EU Logging Subscription**: For monitoring, logging and operational insights (EU regions only)
- **EU Platform Subscription**: For platform services and shared resources (EU regions only)
- **EU Landing Zone Subscription**: For workload deployments and applications (EU regions only)

#### 2.4 Getting Subscription IDs

If your subscriptions follow the recommended naming convention, you can use automatic parsing for verification:

```bash
# Method 1: Automatic parsing using naming convention (if subscriptions follow ALZ-EU-* pattern)
# This method automatically identifies subscriptions based on naming convention

ENVIRONMENT="Prod"  # Change as needed to "Dev" or "Test"
REGION="SwedenCentral"  # Change to your target region

# Parse subscription IDs automatically based on naming convention
MANAGEMENT_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Management-${ENVIRONMENT}-${REGION}')].id" --output tsv)
CONNECTIVITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Connectivity-${ENVIRONMENT}-${REGION}')].id" --output tsv)
IDENTITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Identity-${ENVIRONMENT}-${REGION}')].id" --output tsv)
SECURITY_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Security-${ENVIRONMENT}-${REGION}')].id" --output tsv)
LOGGING_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Logging-${ENVIRONMENT}-${REGION}')].id" --output tsv)
PLATFORM_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-Platform-${ENVIRONMENT}-${REGION}')].id" --output tsv)
LANDINGZONE_SUB=$(az account list --query "[?contains(name, 'ALZ-EU-LandingZone-${ENVIRONMENT}-${REGION}')].id" --output tsv)

# Check that all subscriptions were found
echo "Parsed Subscription IDs:"
echo "Management: $MANAGEMENT_SUB"
echo "Connectivity: $CONNECTIVITY_SUB"
echo "Identity: $IDENTITY_SUB"
echo "Security: $SECURITY_SUB"
echo "Logging: $LOGGING_SUB"
echo "Platform: $PLATFORM_SUB"
echo "Landing Zone: $LANDINGZONE_SUB"

# Validate that all subscription IDs were found (not empty)
if [[ -z "$MANAGEMENT_SUB" || -z "$CONNECTIVITY_SUB" || -z "$IDENTITY_SUB" || -z "$SECURITY_SUB" || -z "$LOGGING_SUB" || -z "$PLATFORM_SUB" || -z "$LANDINGZONE_SUB" ]]; then
    echo "ERROR: Failed to find one or more subscriptions using naming convention."
    echo "Please verify that subscription names follow the ALZ-EU-{PURPOSE}-${ENVIRONMENT}-${REGION} pattern"
    echo "Or use Method 2 below for manual identification."
    exit 1
fi
```

```bash
# Method 2: Manual identification (if subscriptions don't follow naming convention)
# List all available subscriptions and their IDs
az account list --query "[].{Name:name, DisplayName:displayName, ID:id}" --output table

# Note: You must manually identify the correct subscriptions from the above list
# and obtain subscription IDs from your Azure administrator or subscription management process
```

### Step 3: Variables File Configuration

#### 3.1 Manual Variables File Update
```bash
# Update variables.json file with actual subscription IDs and configuration values
# Replace placeholder values with actual values for your environment

# Example using jq (if available)
jq --arg mgmt "$MANAGEMENT_SUB" \
   --arg conn "$CONNECTIVITY_SUB" \
   --arg id "$IDENTITY_SUB" \
   --arg sec "$SECURITY_SUB" \
   --arg log "$LOGGING_SUB" \
   --arg plat "$PLATFORM_SUB" \
   --arg lz "$LANDINGZONE_SUB" \
   --arg location "swedencentral" \
   --arg mgId "your-management-group-id" \
   '.parameters.subscriptionIds.management.value = $mgmt |
    .parameters.subscriptionIds.connectivity.value = $conn |
    .parameters.subscriptionIds.identity.value = $id |
    .parameters.subscriptionIds.security.value = $sec |
    .parameters.subscriptionIds.logging.value = $log |
    .parameters.subscriptionIds.platform.value = $plat |
    .parameters.subscriptionIds.landingZone.value = $lz |
    .parameters.deploymentConfiguration.primaryLocation.value = $location |
    .parameters.deploymentConfiguration.managementGroupId.value = $mgId' \
   variables.json > variables_updated.json

mv variables_updated.json variables.json
```

#### 3.2 Alternative: Direct File Editing
You can also directly edit the `variables.json` file with your preferred text editor:

```bash
# Edit variables.json directly
nano variables.json
# or
vim variables.json
# or
code variables.json
```

Update the following key sections:
- `deploymentConfiguration.environment` and `deploymentConfiguration.region`: Set environment and region for subscription parsing
- `subscriptionIds`: Replace all placeholder subscription IDs with actual values
- `deploymentConfiguration.primaryLocation`: Set to your preferred EU region
- `deploymentConfiguration.managementGroupId`: Set your management group ID

### Step 4: Automated Deployment

#### 4.1 Using the Deployment Script (Recommended)

The repository includes a comprehensive deployment script that automates the entire process:

```bash
# Make the script executable (if not already)
chmod +x deploy-alz.sh

# Run complete deployment
./deploy-alz.sh

# Run with specific environment and region
./deploy-alz.sh --environment Prod --region SwedenCentral

# Run specific deployment steps only
./deploy-alz.sh --management-groups --policy-definitions

# Dry run to see what would be deployed
./deploy-alz.sh --dry-run

# Show all available options
./deploy-alz.sh --help
```

#### 4.2 Deployment Script Features

The deployment script provides:
- **Configuration Management**: Loads configuration from variables.json with command-line override capability
- **Multiple Authentication Methods**: Interactive, service principal, managed identity, and device code authentication
- **Automatic Prerequisites Check**: Verifies Azure CLI, jq, and authentication status
- **Subscription ID Parsing**: Automatically detects subscriptions using naming convention
- **Variable Substitution**: Processes all template files with actual values
- **Modular Deployment**: Run specific deployment steps or complete deployment
- **Error Handling**: Comprehensive error handling and rollback capabilities
- **Backup and Restore**: Automatic backup of files before processing
- **Colored Output**: Clear status indicators and progress reporting

#### 4.3 Configuration Priority

The script follows a clear configuration hierarchy:
1. **Command line arguments** (highest priority)
2. **Values from variables.json file**
3. **Built-in fallback defaults** (lowest priority)

This ensures that the variables.json file serves as the primary configuration source while still allowing runtime overrides when needed.

#### 4.4 Available Deployment Steps

```bash
# Individual deployment steps (can be combined)
./deploy-alz.sh --management-groups           # Deploy management groups
./deploy-alz.sh --policy-definitions          # Deploy custom policy definitions
./deploy-alz.sh --role-definitions            # Deploy custom role definitions
./deploy-alz.sh --logging                     # Deploy logging infrastructure
./deploy-alz.sh --hub-networking              # Deploy hub networking
./deploy-alz.sh --mg-diagnostic-settings      # Deploy management group diagnostic settings
./deploy-alz.sh --subscription-placement      # Deploy subscription placement
./deploy-alz.sh --default-policy-assignments  # Deploy default policy assignments
./deploy-alz.sh --custom-policy-assignments   # Deploy custom policy assignments
./deploy-alz.sh --role-assignments            # Deploy role assignments
```

## Post-Deployment Verification

### Check Deployment Status
```bash
# Check management groups deployment
az deployment tenant show --name "alz-mg-deployment"

# Check policy definitions deployment
az deployment mg show --name "alz-policy-defs" --management-group-id "alz"

# Check logging deployment
az deployment sub show --name "alz-logging" --subscription "$MANAGEMENT_SUB"
```

### Verify Resources
```bash
# List management groups
az account management-group list --query "[].{Name:name, DisplayName:displayName}" --output table

# Check policy assignments
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/alz" --query "[].{Name:name, DisplayName:displayName}" --output table

# Check Log Analytics workspace
az monitor log-analytics workspace list --subscription "$MANAGEMENT_SUB" --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output table
```

## Troubleshooting

### 1. Deployment Errors
```bash
# Check deployment details
az deployment tenant show --name "deployment-name"

# Check deployment operations
az deployment operation list --name "deployment-name"

# Check management group deployment status
az deployment mg show --name "deployment-name" --management-group-id "alz"
```

### 2. Subscription Verification Errors
```bash
# Verify specific EU subscription IDs exist and are accessible
# Replace these with your actual EU subscription IDs
MANAGEMENT_SUB="00000000-0000-0000-0000-000000000001"      # EU Management subscription
CONNECTIVITY_SUB="00000000-0000-0000-0000-000000000002"    # EU Connectivity subscription
IDENTITY_SUB="00000000-0000-0000-0000-000000000003"        # EU Identity subscription
SECURITY_SUB="00000000-0000-0000-0000-000000000004"        # EU Security subscription
LOGGING_SUB="00000000-0000-0000-0000-000000000005"         # EU Logging subscription
PLATFORM_SUB="00000000-0000-0000-0000-000000000006"        # EU Platform subscription
LANDINGZONE_SUB="00000000-0000-0000-0000-000000000007"     # EU Landing Zone subscription

# Check each EU subscription exists and is accessible
for SUB_ID in "$MANAGEMENT_SUB" "$CONNECTIVITY_SUB" "$IDENTITY_SUB" "$SECURITY_SUB" "$LOGGING_SUB" "$PLATFORM_SUB" "$LANDINGZONE_SUB"; do
  echo "Checking EU subscription: $SUB_ID"
  az account show --subscription "$SUB_ID" --query "{Name:name, DisplayName:displayName, State:state, ID:id, Location:tenantId}" --output table
  
  # Verify EU data residency compliance
  echo "Verifying EU data residency for subscription: $SUB_ID"
  
  # Check Owner permissions on subscription
  az role assignment list --assignee $(az account show --query user.name -o tsv) --scope "/subscriptions/$SUB_ID" --query "[?roleDefinitionName=='Owner'].{PrincipalName:principalName, RoleDefinitionName:roleDefinitionName}" --output table
done
```

### 3. Permissions Issues
```bash
# Check current user
az account show --query "{User:user.name, TenantId:tenantId}" --output table

# Check management group permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) --scope "/providers/Microsoft.Management/managementGroups/$(az account management-group list --query "[0].name" -o tsv)" --output table
```

### 4. Resource Provider Registration
```bash
# Register required resource providers
az provider register --namespace Microsoft.Authorization
az provider register --namespace Microsoft.PolicyInsights
az provider register --namespace Microsoft.Management
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Automation

# Check registration status
az provider show --namespace Microsoft.Authorization --query "registrationState"
```

### 5. Script Issues
```bash
# Check script permissions
ls -la deploy-alz.sh

# Make script executable if needed
chmod +x deploy-alz.sh

# Run script with debug output
bash -x deploy-alz.sh --dry-run

# Check script dependencies
./deploy-alz.sh --help
```

## EU Compliance and Data Residency

### Supported EU Azure Regions

This deployment is optimized for European Union Azure regions to ensure data residency compliance:

#### Primary Regions:
- **Sweden Central** (`swedencentral`) - Recommended primary region
- **Germany West Central** (`germanywestcentral`) - Recommended secondary region

#### Additional EU Regions (Optional):
- **West Europe** (`westeurope`) - Netherlands
- **North Europe** (`northeurope`) - Ireland
- **France Central** (`francecentral`) - France
- **Switzerland North** (`switzerlandnorth`) - Switzerland
- **Norway East** (`norwayeast`) - Norway


## Security Considerations

1. **Access Control**: Use Azure AD groups for role assignments instead of individual users
2. **Secrets Management**: Store sensitive data in Azure Key Vault in EU regions
3. **Variable Management**: Never commit actual subscription IDs to source control - use the variable system
4. **Network Security**: Implement proper network security groups and firewall rules
5. **Monitoring**: Enable Azure Security Center and Azure Sentinel in EU regions
6. **Compliance**: Regularly audit policy compliance and role assignments for GDPR compliance
7. **Template Processing**: Ensure variable substitution is completed before deployment
8. **Data Residency**: Verify all resources are deployed within EU boundaries
9. **EU Regulations**: Ensure compliance with local EU country regulations
10. **Script Security**: Review and validate deployment scripts before execution

## Development and Customization

### Using Your Own Deployment Tools

This repository is designed to work with any deployment tool or CI/CD system:

#### Git-based Deployment
```bash
# Clone and customize
git clone <repository-url>
cd GOVEE

# Create your own deployment branch
git checkout -b custom-deployment

# Modify variables.json and templates as needed
# Commit your changes
git add .
git commit -m "Custom deployment configuration"
```

#### Integration with CI/CD Systems

The deployment can be integrated with various CI/CD systems:

**GitHub Actions Example:**
```yaml
name: Deploy Azure Landing Zone
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment (Prod/Dev/Test)'
        required: true
        default: 'Prod'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    - name: Deploy ALZ
      run: |
        chmod +x deploy-alz.sh
        ./deploy-alz.sh --environment ${{ github.event.inputs.environment }}
```

**Jenkins Pipeline Example:**
```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['Prod', 'Dev', 'Test'], description: 'Environment')
        choice(name: 'REGION', choices: ['SwedenCentral', 'GermanyWestCentral'], description: 'Region')
    }
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    chmod +x deploy-alz.sh
                    ./deploy-alz.sh --environment ${ENVIRONMENT} --region ${REGION}
                '''
            }
        }
    }
}
```

### Customizing Templates

All Bicep templates can be customized for your specific requirements:

```bash
# Copy and modify templates
cp -r infra-as-code/bicep/modules custom-modules

# Edit templates as needed
nano custom-modules/managementGroups/managementGroups.bicep

# Use custom templates in deployment
az deployment tenant create \
  --template-file "./custom-modules/managementGroups/managementGroups.bicep"
```

## Next Steps

After successful deployment, consider:

1. **Spoke Networks Deployment**: Deploy spoke virtual networks for workloads
2. **Workload Subscriptions Configuration**: Set up additional subscriptions for specific workloads
3. **Monitoring and Alerting**: Set up additional monitoring and alerting rules
4. **Backup Strategies**: Implement backup strategies for critical resources
5. **Disaster Recovery**: Plan and test disaster recovery procedures
6. **Compliance Auditing**: Set up regular compliance audits
7. **Cost Management**: Implement cost management and optimization practices
8. **Security Hardening**: Implement additional security hardening measures
9. **Custom Automation**: Develop custom automation scripts for your specific needs
10. **Documentation**: Create organization-specific documentation and runbooks

## Support and Documentation

For additional support and documentation:
- See `VARIABLES_README.md` for detailed documentation of the variables file
- Check Azure Landing Zone official documentation
- Consult Azure best practices guide
- Visit Azure Architecture Center for architecture guidance
- Review the deployment script help: `./deploy-alz.sh --help`

## Contributing

To contribute to this repository:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request