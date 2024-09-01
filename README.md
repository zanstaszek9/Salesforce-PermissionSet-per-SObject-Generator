# Salesforce PermissionSet-per-SObject-Generator
Script that uses Salesforce CLI `sf sobject describe` call to generate Permission Set file with all fields for that object. Configurable by JSON.

This PowerShell script automates the generation of Salesforce Permission Sets. By utilizing the Salesforce CLI, it retrieves object metadata and generates XML files based on a template from JSON file. The script supports input as a direct list of object names or through a text file. Permission Sets are grouped by SObject and saved in designated subdirectories. This tool helps Salesforce developers streamline the process of creating multiple Permission Sets with varying permissions, allowing for consistent permissions.

## Features
- Automatically generate Permission Set XML files based on Salesforce object descriptions.
- Support for both direct input and file-based input.
- JSON-based configuration for defining Permission Set structure.
- Automated folder creation and organization of Permission Sets by SObject.

## Requirements
- [SalesForce CLI](https://developer.salesforce.com/tools/salesforcecli/)
  - Tested on version `@salesforce/cli/2.56.7 win32-x64 node-v20.16.0`
- Powershell 

## Generated example
`PS> ./generatePermissionsSets.ps1  -s Opportunity` for following JSON `permissionSetsTemplate.json`:

```json
[
  {
    "ApiName": "View_{sObjectName}",
    "Label": "View {sObjectName}",
    "Description": "Read only all {sObjectName} fields",
    "FieldEditable": false,
    "ObjCreate": false,
    "ObjEdit": false,
    "ObjDelete": false
  },
  {
    "ApiName": "Create_{sObjectName}",
    "Label": "Create {sObjectName}",
    "Description": "Read and Create all {sObjectName} fields",
    "FieldEditable": true,
    "ObjCreate": true,
    "ObjEdit": false,
    "ObjDelete": false
  }
]
```

#### `View_Opportunity.permissionset-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Read only all Opportunity fields</description>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.AccountId</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.Description</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.Amount</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.Probability</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.Type</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.NextStep</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Opportunity.LeadSource</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>View Opportunity</label>
    <objectPermissions>
        <allowCreate>false</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>false</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Opportunity</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
</PermissionSet>

```

#### `Create_Opportunity.permissionset-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Read and Create all Opportunity fields</description>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.AccountId</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.Description</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.Amount</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.Probability</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.Type</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.NextStep</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.LeadSource</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>Create Opportunity</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>false</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Opportunity</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
</PermissionSet>

```


