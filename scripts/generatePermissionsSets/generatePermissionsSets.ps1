<#
    .SYNOPSIS
    Generates Permission Sets for Salesforce by doing SF CLI call on SObject Describe. You can specify one or more object names directly, or provide a path to a text file that contains a list of object names.

    .PARAMETER $sObjectNamesOrFilePath
    Required
    A comma-separated list of object names or a path to a text file containing object names, one per line.
    For more insight, look here: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_sobject_commands_unified.htm#cli_reference_sobject_describe_unified

    .PARAMETER $targetOrg
    Required
    Username or alias of the target org. Not required if the `target-org` configuration variable is already set.

    .DESCRIPTION
    This script generates Permission Set XML files for provided Salesforce objects. Objects fields are taken from 'sf sobject describe' call, and filtered on "permissionable" parameter.
    You can specify one or more object names directly, or provide a path to a text file that contains a list of object names.
    Permission Set's API Name, Label, Description and object/field permission are taken from JSON file, 'permissionSetsTemplate.json'.
    Script tries to find 'permissionset' folder by recursive search. If failed, folder will be created in root directory.
    Generated Permission Sets are grouped by SObject and saved in separate subdirectories named after the SObject.
    Apparently, Salesforce professionals are creating multiple Permission Sets with different acceses per each SObject. Whether it is a good practice or not, the following script helps to automate that approach.

    .EXAMPLE
    ./generatePermissionsSets.ps1 -s Account
    Generates permission sets for the Account objects.

     .EXAMPLE
    ./generatePermissionsSets.ps1 -s Account -o targetOrg
    Generates permission sets for the Account objects, received from target org.

    .EXAMPLE
    ./generatePermissionsSets.ps1 -s Account, Contact, Opportunity
    Generates permission sets for the Account, Contact, and Opportunity objects.

    .EXAMPLE
    ./generatePermissionsSets.ps1 -s ./textFileWithObjectNames.txt
    Reads object names from a text file and generates permission sets for each object.

    .EXAMPLE
    ./generatePermissionsSets.ps1 -s "D:/Salesforce Repositories/textFileWithObjectNames.txt"
    Reads object names from a text file and generates permission sets for each object.
    Directory with whitespaces in filepath requires surrounding by double quotes.

#>

param(
    [Alias("s")][string[]]$sObjectNamesOrFilePath,  # One or more object names separated by commas, or a path to a text file with object names, one per line
    [Alias("o")][string]$targetOrg

)


function Get-PermissionSetsFolder
{
    # Look for the folder named "permissionsets" in subfolders. If not found, create one.
    $permissionSetsFolder = (Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -and $_.Name.Equals("permissionsets") } | Select-Object -First 1).FullName
    if ($null -ne $permissionSetsFolder)
    {
        return $permissionSetsFolder
    }
    else
    {
        Write-Warning "Warning: 'permissionsets' folder not found. Creating folder in root directory."
        $permissionSetsFolder = "permissionsets"
        if (-not (Test-Path -Path $permissionSetsFolder))
        {
            New-Item -ItemType Directory -Path $permissionSetsFolder -Force
        }
        return $permissionSetsFolder
    }
}

# Check if the -s parameter is a file path
if ($sObjectNamesOrFilePath.count -eq 1 -and (Test-Path $sObjectNamesOrFilePath -PathType Leaf))
{
    # If the file path exists, read object names from the file
    $sObjectNames = Get-Content -Path $sObjectNamesOrFilePath
}
else
{
    # If not a file path, treat as a list of object names
    $sObjectNames = $sObjectNamesOrFilePath -split ',\s*'
}

# Get JSON template file with structure data for Permission Sets
$permissionSetsTemplateFilePath = "${PSScriptRoot}/permissionSetsTemplate.json"
if (-not (Test-Path -Path $permissionSetsTemplateFilePath))
{
    Write-Error "The permission sets configuration file '$permissionSetsTemplateFilePath' does not exist."
    exit
}
$permissionSetsTemplates = Get-Content -Path $permissionSetsTemplateFilePath | ConvertFrom-Json

# Search for the permissionsets folder
$permissionSetsFolder = Get-PermissionSetsFolder



foreach ($sObjectName in $sObjectNames)
{
    $sObjectName = $sObjectName.Trim()  # Remove unnecessary whitespace

    Write-Host "Processing SObject: " $sObjectName -f DarkCyan

    # Retrieve SObject description using SF CLI (SFDX) and convert to JSON
    $sobjectDescriptionJson = sf sobject describe --sobject $sObjectName -o $targetOrg | ConvertFrom-Json   #https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_sobject_commands_unified.htm#cli_reference_sobject_describe_unified

    # Prepare Tab Name for tabVisibility
    $isCustom = $sobjectDescriptionJson.custom;
    $tabName = If ($isCustom) {"$sObjectName"} Else {"standard-$sObjectName"} #Example: standard-Account, standard-ServiceAppointment

    if ($null -eq $sobjectDescriptionJson)
    {
        Write-Error "Something went wrong during SF CLI call. The command output is empty. Input passed: '$sObjectName'"
        exit;
    }
    # Filter fields with "permissionable" set to "true" and are not compound fields - Compound fields are managed by the container field (ex. BillingAddress), not their elements (ex. BillingStreet)
    $filteredFields = $sobjectDescriptionJson.fields | Where-Object { $_.permissionable -eq $true -and $_.compoundFieldName -eq $null }



    $permissionSetsSObjectSubfolder = (Get-ChildItem $permissionSetsFolder -Recurse | Where-Object { $_.PSIsContainer -and $_.Name.Equals(${sObjectName}) } | Select-Object -First 1).FullName
    if ($null -eq $permissionSetsSObjectSubfolder)
    {
        New-Item -ItemType Directory -Path "${permissionSetsFolder}/${sObjectName}" -Force
    }


    # Iterate over each Permission Set tepmlate and generate the corresponding XML file
    foreach ($permissionSetTemplate in $permissionSetsTemplates)
    {

        $apiName = $permissionSetTemplate.ApiName -replace '\{sObjectName\}', $sObjectName
        $label = $permissionSetTemplate.Label -replace '\{sObjectName\}', $sObjectName
        $description = $permissionSetTemplate.Description -replace '\{sObjectName\}', $sObjectName
        $fieldEditable = $permissionSetTemplate.FieldEditable.ToString().ToLower()
        $objCreate = $permissionSetTemplate.ObjCreate.ToString().ToLower()
        $objEdit = $permissionSetTemplate.ObjEdit.ToString().ToLower()
        $objDelete = $permissionSetTemplate.ObjDelete.ToString().ToLower()
        $tabVisibility = ($permissionSetTemplate.TabVisibility, 'None', 1 -ne $null)[0] #https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionset.htm#PermissionSetTabVisibility_title

        $xmlFileName = "${permissionSetsFolder}/${sObjectName}/${apiName}.permissionset-meta.xml"



        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>$description</description>

"@

        # Add fieldPermissions section for each field
        foreach ($field in $filteredFields)
        {
            $fieldName = $field.name
            $xmlContent += @"
    <fieldPermissions>
        <editable>$fieldEditable</editable>
        <field>$sObjectName.$fieldName</field>
        <readable>true</readable>
    </fieldPermissions>

"@
        }

        $xmlContent += @"
    <hasActivationRequired>false</hasActivationRequired>
    <label>$label</label>
    <objectPermissions>
        <allowCreate>$objCreate</allowCreate>
        <allowDelete>$objDelete</allowDelete>
        <allowEdit>$objEdit</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>$sObjectName</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <tabSettings>
        <tab>$tabName</tab>
        <visibility>$tabVisibility</visibility>
    </tabSettings>
</PermissionSet>
"@

        # Save to file
        $xmlContent | Out-File -FilePath $xmlFileName -Encoding UTF8

        Write-Host "Permission Set XML file has been generated and saved as $xmlFileName" -f DarkGreen
    }
}
