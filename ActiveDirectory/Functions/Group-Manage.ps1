function Group-Manage {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The name of the group you would like to manage")]
        [string] $GroupName,
        [Parameter(Mandatory = $true, HelpMessage = "'ChangeOwner' (Change manager of group), 'Add' or 'Remove' members of the group.")]
        [ValidateSet("ChangeOwner", "Add", "Remove")]
        [string] $GroupAction,
        [Parameter(Mandatory = $true, HelpMessage = "Comma separated list of members to add or remove from the group. or the new owner of the group. DistinguishedName, sAMAccountName or GUID are all valid.")]
        [array] $GroupMembers,
        [Parameter(Mandatory = $false, HelpMessage = "The domain controller to run against. If you do not specify this it will run against the domain controller of the local machine")]
        [string] $DomainController = ((nltest /dsgetdc:)[0].split('\\') | select-object -Last 1), # Get the domain controller from the local machine
        [Parameter(Mandatory = $false, HelpMessage = "Credentials to run the command with if you do not specify this it will run as the current user")]
        [pscredential] $Credential 
    )
    # Get the group object
    if ($Credential) {
        $Group = Get-ADGroup -Identity $GroupName -Properties ManagedBy -Server $DomainController -Credential $Credential
    }
    else {
        $Group = Get-ADGroup -Identity $GroupName -Properties ManagedBy -Server $DomainController
    }
    # Check if the group exists
    if ($null -eq $Group) {
        Write-Error "Group $GroupName does not exist"
        return "Group $GroupName does not exist"
    }
    # Check if GroupMember is empty
    if ($GroupMembers -eq $null) {
        Write-Error "GroupMember is empty"
        return "GroupMember is empty"
    }
    # Check if GroupAction is ChangeOwner
    if ($GroupAction -eq "ChangeOwner") {
        # Check if GroupMember is a single value
        if ($GroupMembers.Count -gt 1) {
            Write-Error "GroupMember can only be a single value when GroupAction is ChangeOwner"
            return "GroupMember can only be a single value when GroupAction is ChangeOwner"
        }

        # Check if GroupMember is a valid user
        if ($Credential) {
            $User = Get-ADUser -Identity ($GroupMembers -join "") -Server $DomainController -Credential $Credential
        }
        else {
            $User = Get-ADUser -Identity ($GroupMembers -join "") -Server $DomainController
        }
        if ($null -eq $User) {
            Write-Error "GroupMember $GroupMembers is not a valid user"
            return "GroupMember $GroupMember is not a valid user"
        }

        # Check if GroupMember is already the owner
        if ($Group.ManagedBy -eq $GroupMembers) {
            return "GroupMember $GroupMembers is already the owner of $GroupName"
        }

        # Change the owner of the group
        if ($Credential) {
            Set-ADGroup -Identity $GroupName -ManagedBy ($GroupMembers -join "") -Server $DomainController -Credential $Credential
        }
        else {
            Set-ADGroup -Identity $GroupName -ManagedBy ($GroupMembers -join "") -Server $DomainController
        }
        return "GroupMember $GroupMembers is now the owner of $GroupName"

    }
    elseif ($GroupAction -eq "Add") {
        # Add members to the group
        if ($Credential) {
            Add-ADGroupMember -Identity $GroupName -Members $GroupMembers -Server $DomainController -Credential $Credential
        }
        else {
            Add-ADGroupMember -Identity $GroupName -Members $GroupMembers -Server $DomainController
        }
        return "GroupMember(s) $GroupMembers added to $GroupName"
        
    }
    elseif ($GroupAction -eq "Remove") {
        # Remove members from the group
        if ($Credential) {
            Remove-ADGroupMember -Identity $GroupName -Members $GroupMembers -Confirm:$false -Server $DomainController -Credential $Credential
        }
        else {
            Remove-ADGroupMember -Identity $GroupName -Members $GroupMembers -Confirm:$false -Server $DomainController
        }
        return "GroupMember(s) $GroupMembers removed from $GroupName"
    }
}