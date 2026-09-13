# Variables Documentation - EU Deployment

This document describes the variables file (`variables.json`) that contains all subscription identifiers and configuration values used throughout the Azure Landing Zone (ALZ) infrastructure code optimized for European Union deployments.

## Overview

The `variables.json` file centralizes all subscription IDs and configuration values to make the infrastructure code more maintainable and environment-agnostic. This configuration is specifically designed for EU Azure regions to ensure data residency compliance and GDPR adherence.

**⚠️ IMPORTANT: This variables file contains placeholders since subscriptions haven't been created yet. You must update these values with actual EU subscription IDs before deployment.**

## EU Compliance Features

- **Data Residency**: All resources deployed within EU boundaries
- **Primary Region**: Sweden Central (`swedencentral`)
- **Secondary Region**: Germany West Central (`germanywestcentral`)
- **GDPR Compliance**: Configuration supports GDPR requirements
- **EU Regulations**: Compliant with EU data protection laws

## File Structure

The variables file is organized into the following categories:

### Deployment Configuration

- **deploymentConfiguration.environment**: Environment for subscription parsing (Prod, Dev, Test) - used by deployment script
- **deploymentConfiguration.region**: Region for subscription parsing (SwedenCentral, GermanyWestCentral, etc.) - used by deployment script  
- **deploymentConfiguration.primaryLocation**: Primary EU Azure region for deployments (default: `swedencentral`)
- **deploymentConfiguration.secondaryLocation**: Secondary EU Azure region for multi-region deployments (default: `germanywestcentral`)
- **deploymentConfiguration.managementGroupId**: Root management group ID for Azure Landing Zone
- **deploymentConfiguration.topLevelManagementGroupPrefix**: Management group hierarchy prefix
- **deploymentConfiguration.topLevelManagementGroupSuffix**: Optional management group hierarchy suffix
- **deploymentConfiguration.topLevelManagementGroupDisplayName**: Top level management group display name

### Authentication Configuration

Configuration for Azure authentication methods:

- **authenticationConfiguration.method**: Authentication method (interactive, service-principal, managed-identity, device-code)
- **authenticationConfiguration.tenantId**: Azure AD Tenant ID (required for service principal authentication)
- **authenticationConfiguration.servicePrincipalId**: Service Principal Application ID (required for service principal authentication)
- **authenticationConfiguration.servicePrincipalSecret**: Service Principal Secret (use environment variable or Azure Key Vault reference)
- **authenticationConfiguration.subscriptionId**: Default subscription ID to set after authentication

**Security Note**: For service principal authentication, it's recommended to use environment variables (`AZURE_CLIENT_SECRET` or `ARM_CLIENT_SECRET`) instead of storing secrets in the variables file.

### Subscription IDs

All Azure subscription identifiers required for Azure Landing Zone deployment:

- **management**: Management subscription ID
- **connectivity**: Connectivity subscription ID  
- **landingZone**: Landing zone subscription ID
- **identity**: Identity subscription ID
- **security**: Security subscription ID
- **logging**: Logging subscription ID
- **platform**: Platform subscription ID
- **workload1**: Workload subscription ID 1
- **workload2**: Workload subscription ID 2

### Resource Groups and Resource Names

- **resourceGroupNames**: Standardized resource group names for different services
- **resourceNames**: Common resource names used across the infrastructure
- **resourceNames.dataCollectionRules**: Data collection rule names for Azure Monitor Agent

### Policy Configuration

- **policyConfiguration.customPolicyAssignment**: Custom policy assignment settings including name, display name, description, definition ID, and non-compliance messages

### Container Registry Configuration

- **containerRegistry.sku**: Azure Container Registry SKU
- **containerRegistry.tags**: Container registry resource tags

### Log Analytics Configuration

- **logAnalyticsConfiguration**: Log Analytics workspace settings including retention, resource category, and SKU

## Pre-Deployment Setup

### 1. Required EU Subscriptions with Naming Convention

**IMPORTANT**: Subscriptions must be created manually through your organization's subscription management process. This deployment does not create subscriptions programmatically.

Before using this variables file, ensure that the required EU-compliant subscriptions exist in your Azure environment following the recommended naming convention:

#### Recommended Naming Pattern:
```
ALZ-EU-{PURPOSE}-{ENVIRONMENT}-{REGION}
```

#### Required Subscription Names for Production Environment:
```
ALZ-EU-Management-Prod-SwedenCentral
ALZ-EU-Connectivity-Prod-SwedenCentral
ALZ-EU-Identity-Prod-SwedenCentral
ALZ-EU-Security-Prod-SwedenCentral
ALZ-EU-Logging-Prod-SwedenCentral
ALZ-EU-Platform-Prod-SwedenCentral
ALZ-EU-LandingZone-Prod-SwedenCentral
```

#### Required Subscription Names for Development Environment:
```
ALZ-EU-Management-Dev-SwedenCentral
ALZ-EU-Connectivity-Dev-SwedenCentral
ALZ-EU-Identity-Dev-SwedenCentral
ALZ-EU-Security-Dev-SwedenCentral
ALZ-EU-Logging-Dev-SwedenCentral
ALZ-EU-Platform-Dev-SwedenCentral
ALZ-EU-LandingZone-Dev-SwedenCentral
```

#### Alternative Regions Examples:
```
ALZ-EU-Management-Prod-GermanyWestCentral
ALZ-EU-Connectivity-Prod-WestEurope
ALZ-EU-Identity-Prod-NorthEurope
# ... etc.
```

**Note**: These subscriptions must be created manually by subscription provisioning process before running the deployment.

#### Naming Convention Benefits:
- **Automatic Parsing**: Deployment scripts can automatically identify and parse subscription IDs
- **Environment Separation**: Clear distinction between environments (Prod, Dev, Test)
- **Regional Identification**: Easy identification of target deployment regions
- **Compliance Tracking**: EU designation ensures data residency compliance
- **Consistent Structure**: Standardized naming across all subscriptions

#### Important Notes:
- Ensure all subscriptions are configured for EU data residency
- Verify subscription policies restrict resource deployment to EU regions only
- Follow the exact naming pattern for automatic parsing to work

### 2. Get EU Subscription IDs

After the required EU subscriptions have been manually created by your organization, retrieve their IDs:

```bash
# List all EU subscriptions and their IDs
az account list --query "[].{Name:name, ID:id}" --output table

# Or get specific EU subscription ID
az account show --name "ALZ-EU-Management" --query "id" --output tsv

# Verify EU data residency compliance for each subscription
az account show --name "ALZ-EU-Management" --query "{Name:name, ID:id, TenantId:tenantId}" --output table
```

### 3. Update Variables File

Replace the placeholder values in `variables.json` with actual EU subscription IDs:

```json
{
  "subscriptionIds": {
    "management": {
      "value": "actual-eu-management-subscription-id-here"
    },
    "connectivity": {
      "value": "actual-eu-connectivity-subscription-id-here"
    }
    // ... update all other EU subscription IDs
  },
  "deploymentConfiguration": {
    "primaryLocation": {
      "value": "swedencentral"  // Primary EU region
    },
    "secondaryLocation": {
      "value": "germanywestcentral"  // Secondary EU region
    }
  }
}
```

## Usage

### In Bicep Templates

Reference variables as follows:

```bicep
param parManagementSubscriptionId string = '{{subscriptionIds.management.value}}'
param parConnectivitySubscriptionId string = '{{subscriptionIds.connectivity.value}}'
param parPrimaryLocation string = '{{deploymentConfiguration.primaryLocation.value}}'
```

### In JSON Parameter Files

```json
{
  "parManagementSubscriptionId": {
    "value": "{{subscriptionIds.management.value}}"
  },
  "parLocation": {
    "value": "{{deploymentConfiguration.primaryLocation.value}}"
  }
}
```

### In Deployment Scripts

The deployment script uses these variables for configuration:

```bash
# Variables loaded from variables.json
ENVIRONMENT=$(jq -r '.parameters.deploymentConfiguration.environment.value' variables.json)
REGION=$(jq -r '.parameters.deploymentConfiguration.region.value' variables.json)
DEPLOYMENT_LOCATION=$(jq -r '.parameters.deploymentConfiguration.primaryLocation.value' variables.json)
MANAGEMENT_GROUP_ID=$(jq -r '.parameters.deploymentConfiguration.managementGroupId.value' variables.json)
TOP_LEVEL_MG_PREFIX=$(jq -r '.parameters.deploymentConfiguration.topLevelManagementGroupPrefix.value' variables.json)

# Example usage in deployment commands
az deployment tenant create \
  --name "alz-mg-deployment" \
  --location "$DEPLOYMENT_LOCATION" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --template-file "./infra-as-code/bicep/modules/managementGroups/managementGroups.bicep"

# Environment and Region are used for automatic subscription parsing
# e.g., looking for subscriptions named: ALZ-EU-Management-${ENVIRONMENT}-${REGION}
```

## Validation Checklist

Before deployment, ensure you have:

- [ ] Verified all required EU subscriptions have been manually created with data residency compliance
- [ ] Updated all EU subscription IDs in `variables.json`
- [ ] Configured authentication method and credentials in `variables.json`
- [ ] Updated deployment configuration (environment and region for subscription parsing)
- [ ] Verified deployment script has executable permissions
- [ ] Updated management group ID
- [ ] Updated location to your preferred EU region (default: swedencentral)
- [ ] Verified all placeholders have been replaced
- [ ] Confirmed all subscriptions are restricted to EU regions
- [ ] Tested template processing script
- [ ] Validated parameter files after variable replacement
- [ ] Verified GDPR compliance settings
- [ ] Confirmed data residency requirements are met

## EU Region Selection Guide

### Recommended EU Regions

#### Primary Options:
- **Sweden Central** (`swedencentral`) - Recommended for most EU deployments
- **Germany West Central** (`germanywestcentral`) - Alternative primary region

#### Secondary Options:
- **West Europe** (`westeurope`) - Netherlands, established region
- **North Europe** (`northeurope`) - Ireland, established region
- **France Central** (`francecentral`) - For French data residency requirements
- **Switzerland North** (`switzerlandnorth`) - For Swiss data residency requirements
- **Norway East** (`norwayeast`) - For Nordic data residency requirements

### Region Selection Criteria:
1. **Data Residency Requirements**: Choose based on your organization's data residency needs
2. **Latency**: Select regions closest to your users
3. **Service Availability**: Verify all required Azure services are available
4. **Compliance**: Ensure region meets your regulatory requirements
5. **Disaster Recovery**: Select secondary region in different country for DR

## Benefits

1. **Centralized Configuration**: All subscription IDs managed in one place
2. **Environment Flexibility**: Easy deployment to different EU environments
3. **Maintainability**: Subscription ID changes require only variables file updates
4. **Consistency**: Ensures all files use the same subscription IDs
5. **Security**: Reduces risk of accidentally committing hardcoded subscription IDs
6. **Pre-deployment Ready**: Placeholder values make it clear what needs updating
7. **EU Compliance**: Built-in support for EU data residency and GDPR requirements
8. **Regional Flexibility**: Easy switching between EU regions as needed

## Notes

- Variable placeholders use the format `{{variableName}}` for easy identification
- All subscription IDs are stored as GUIDs in the variables file
- The variables file follows the Azure Resource Manager parameter file schema
- **Never commit actual subscription IDs to source control** - use placeholder values in the repository
- Consider using Azure Key Vault or environment variables for storing actual subscription IDs in production
- The placeholder subscription IDs (00000000-0000-0000-0000-000000000001, etc.) are invalid and will cause deployment failures if not replaced
- **EU Data Residency**: Ensure all subscriptions are configured to restrict resources to EU regions only
- **GDPR Compliance**: Verify that logging and monitoring configurations support GDPR requirements
- **Regional Restrictions**: Implement Azure policies to prevent resource deployment outside EU regions
- **Default EU Regions**: Primary region is set to Sweden Central, secondary to Germany West Central for optimal EU coverage 