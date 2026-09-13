targetScope = 'managementGroup'

@sys.description('Policy assignment name for ISO compliance assessment')
param policyAssignmentName string = '{{policyConfiguration.customPolicyAssignment.name.value}}'

@sys.description('Policy definition ID for ISO compliance policy set')
param policyDefinitionID string = '{{policyConfiguration.customPolicyAssignment.definitionId.value}}'

@sys.description('Display name for the policy assignment')
param policyDisplayName string = '{{policyConfiguration.customPolicyAssignment.displayName.value}}'

@sys.description('Description for the policy assignment')
param policyDescription string = '{{policyConfiguration.customPolicyAssignment.description.value}}'

@sys.description('Non-compliance message for policy violations')
param nonComplianceMessage string = '{{policyConfiguration.customPolicyAssignment.nonComplianceMessage.value}}'

@sys.description('Azure region for the policy assignment')
param parLocation string = '{{deploymentConfiguration.primaryLocation.value}}'

resource assignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: policyAssignmentName
  identity: {
    type: 'SystemAssigned'  
  }
  location: parLocation
  properties: {
    policyDefinitionId: policyDefinitionID
    description: policyDescription
    displayName: policyDisplayName
    nonComplianceMessages: [
      {
        message: nonComplianceMessage
      }
    ]
  }
}
 
output assignmentId string = assignment.id