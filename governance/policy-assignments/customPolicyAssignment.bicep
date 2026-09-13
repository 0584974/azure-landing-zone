targetScope = 'managementGroup'

@description('Policy assignment name')
param policyAssignmentName string

@description('Policy definition or initiative ID')
param policyDefinitionID string

@description('Display name for the policy assignment')
param policyDisplayName string

@description('Description for the policy assignment')
param policyDescription string

@description('Non-compliance message for policy violations')
param nonComplianceMessage string

@description('Azure region for the policy assignment identity')
param parLocation string

resource assignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: policyAssignmentName
  location: parLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: policyDefinitionID
    description: policyDescription
    displayName: policyDisplayName
    enforcementMode: 'Default'
    nonComplianceMessages: [
      {
        message: nonComplianceMessage
      }
    ]
  }
}

output assignmentId string = assignment.id
