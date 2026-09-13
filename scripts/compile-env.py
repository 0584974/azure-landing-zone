#!/usr/bin/env python3
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
environment = sys.argv[1] if len(sys.argv) > 1 else 'prod'
env_dir = root / 'environments' / environment
compiled_dir = env_dir / 'compiled'
compiled_dir.mkdir(parents=True, exist_ok=True)

required = ['global.json', 'subscriptions.json', 'policy.json', 'logging.json', 'networking.json']
for name in required:
    path = env_dir / name
    if not path.exists():
        raise SystemExit(f'[ERROR] Missing {path}')


def load(name: str):
    with open(env_dir / name, 'r', encoding='utf-8') as f:
        return json.load(f)


g = load('global.json')
s = load('subscriptions.json')
p = load('policy.json')
l = load('logging.json')

context = {
    'environment': g['environment'],
    'managementGroupId': g['managementGroupId'],
    'primaryLocation': g['primaryLocation'],
    'topLevelManagementGroupPrefix': g['topLevelManagementGroupPrefix'],
    'topLevelManagementGroupSuffix': g['topLevelManagementGroupSuffix'],
    'subscriptions': s,
    'policyAssignmentName': p['customPolicyAssignment']['name'],
    'logAnalyticsWorkspaceName': l['resourceNames']['logAnalyticsWorkspace'],
}

variables_generated = {
    '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
    'contentVersion': '1.0.0.0',
    'parameters': {
        'deploymentConfiguration': {
            'environment': {'value': g['environment']},
            'region': {'value': g['region']},
            'primaryLocation': {'value': g['primaryLocation']},
            'secondaryLocation': {'value': g['secondaryLocation']},
            'managementGroupId': {'value': g['managementGroupId']},
            'topLevelManagementGroupPrefix': {'value': g['topLevelManagementGroupPrefix']},
            'topLevelManagementGroupSuffix': {'value': g['topLevelManagementGroupSuffix']},
            'topLevelManagementGroupDisplayName': {'value': g['topLevelManagementGroupDisplayName']},
        },
        'subscriptionIds': {k: {'value': v} for k, v in s.items()},
        'resourceGroupNames': {k: {'value': v} for k, v in l['resourceGroupNames'].items()},
        'resourceNames': {
            'logAnalyticsWorkspace': {'value': l['resourceNames']['logAnalyticsWorkspace']},
            'automationAccount': {'value': l['resourceNames']['automationAccount']},
            'userAssignedIdentity': {'value': l['resourceNames']['userAssignedIdentity']},
            'dataCollectionRules': {
                'vmInsights': {'value': l['resourceNames']['dataCollectionRules']['vmInsights']},
                'changeTracking': {'value': l['resourceNames']['dataCollectionRules']['changeTracking']},
                'mdfcSql': {'value': l['resourceNames']['dataCollectionRules']['mdfcSql']},
            },
        },
        'policyConfiguration': {
            'customPolicyAssignment': {
                'name': {'value': p['customPolicyAssignment']['name']},
                'displayName': {'value': p['customPolicyAssignment']['displayName']},
                'description': {'value': p['customPolicyAssignment']['description']},
                'definitionId': {'value': p['customPolicyAssignment']['definitionId']},
                'nonComplianceMessage': {'value': p['customPolicyAssignment']['nonComplianceMessage']},
            }
        },
        'logAnalyticsConfiguration': {
            'retentionInDays': {'value': l['logAnalyticsConfiguration']['retentionInDays']},
            'resourceCategory': {'value': l['logAnalyticsConfiguration']['resourceCategory']},
            'skuName': {'value': l['logAnalyticsConfiguration']['skuName']},
        },
    },
}

workspace = (
    f"/subscriptions/{s['logging']}/resourceGroups/{l['resourceGroupNames']['logging']}"
    f"/providers/Microsoft.OperationalInsights/workspaces/{l['resourceNames']['logAnalyticsWorkspace']}"
)
mgdiag = {
    '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
    'contentVersion': '1.0.0.0',
    'parameters': {
        'parTopLevelManagementGroupPrefix': {'value': g['topLevelManagementGroupPrefix']},
        'parTopLevelManagementGroupSuffix': {'value': g['topLevelManagementGroupSuffix']},
        'parLogAnalyticsWorkspaceResourceId': {'value': workspace},
        'parDiagnosticSettingsName': {'value': 'toLa'},
        'parLandingZoneMgAlzDefaultsEnable': {'value': True},
        'parPlatformMgAlzDefaultsEnable': {'value': True},
        'parLandingZoneMgConfidentialEnable': {'value': False},
        'parTelemetryOptOut': {'value': False},
    },
}

subplacement = {
    '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
    'contentVersion': '1.0.0.0',
    'parameters': {
        'parTopLevelManagementGroupPrefix': {'value': g['topLevelManagementGroupPrefix']},
        'parTopLevelManagementGroupSuffix': {'value': g['topLevelManagementGroupSuffix']},
        'parPlatformManagementMgSubs': {'value': [s['management']]},
        'parPlatformConnectivityMgSubs': {'value': [s['connectivity']]},
        'parPlatformIdentityMgSubs': {'value': [s['identity']]},
        'parPlatformMgSubs': {'value': [s['platform']]},
        'parLandingZonesCorpMgSubs': {'value': [s['landingZone'], s['workload1'], s['workload2']]},
        'parTelemetryOptOut': {'value': False},
    },
}

policy_assignment = {
    '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
    'contentVersion': '1.0.0.0',
    'parameters': {
        'policyAssignmentName': {'value': p['customPolicyAssignment']['name']},
        'policyDefinitionID': {'value': p['customPolicyAssignment']['definitionId']},
        'policyDisplayName': {'value': p['customPolicyAssignment']['displayName']},
        'policyDescription': {'value': p['customPolicyAssignment']['description']},
        'nonComplianceMessage': {'value': p['customPolicyAssignment']['nonComplianceMessage']},
        'parLocation': {'value': g['primaryLocation']},
    },
}

outputs = {
    'context.json': context,
    'variables.generated.json': variables_generated,
    'mgDiagSettingsAll.parameters.json': mgdiag,
    'subPlacementAll.parameters.json': subplacement,
    'policyAssignment.parameters.json': policy_assignment,
}

for name, content in outputs.items():
    with open(compiled_dir / name, 'w', encoding='utf-8') as f:
        json.dump(content, f, indent=2)
        f.write('\n')

print(f'[INFO] Compiled artifacts written to {compiled_dir}')
