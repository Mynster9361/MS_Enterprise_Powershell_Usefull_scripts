function StartHTML {
	param (
		$Totalamountofgroups
	)
	$StartHTML = @"
	<!DOCTYPE html>
	<html>
	
	<head>
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<style>
			.collapsible {
				background-color: #777;
				color: white;
				cursor: pointer;
				width: 100%;
				border: none;
                padding: 18px;
				text-align: left;
				outline: none;
				font-size: 15px;
			}
            .collapsible.empty {
                background-color: #B21807;
            }
	        .colaps {
                display: none; 
                border-left: 2px solid black;
                border-bottom: 2px solid black;
                padding: 10px;
                margin-left: 20px;
                margin-bottom: 10px;
            }
			.active,
			.collapsible:hover {
				background-color: #555;
			}
			.collapsible.empty:hover {
				background-color: #8B0000;
			}
	
			.content {
				padding: 0 18px;
				display: none;
				overflow: hidden;
				background-color: #f1f1f1;
			}
	
			table {
				border-collapse: collapse;
				border-spacing: 0;
                margin-bottom: 10px;
				width: 100%;
				border: 1px solid #ddd;
			}
	
			th,
			td {
				text-align: left;
				padding: 8px;
			}
	
			tr:nth-child(even) {
				background-color: #f2f2f2
			}
		</style>
	</head>
	
	<body>
		<!-- Header: -->
		<h2>Groups in total: $Totalamountofgroups</h2>
"@
	Return $StartHTML
}
function StartCollapsibleTable {
	param (
		$GroupName,
		$Description,
		$Totalamountofmembers
	)
	if ($Totalamountofmembers -eq 0) {
		$CollapsibleTablecheck = @"
	    <!-- Collapsible: -->
        <div>
	    <button type="button" class="collapsible empty">$GroupName - Description: $Description</button>
"@
	}
 else {
		$CollapsibleTablecheck = @"
	    <!-- Collapsible: -->
        <div>
	    <button type="button" class="collapsible">$GroupName - Description: $Description</button>
"@
	}


	$CollapsibleTable = $CollapsibleTablecheck + @"
	<div class="colaps">
		<!-- Normal text: -->
		<p>Total amount of members: $Totalamountofmembers (The below table is not recursive this is only direct members)</p>
		<!-- Table headers: -->
		<table>
			<tr>
				<th>Name:</th>
				<th>UPN:</th>
				<th>Enabled:</th>
				<th>Description:</th>
				<th>Distinguished Name:</th>
			</tr>
"@
	Return $CollapsibleTable
}
function TableData {
	param (
		$MemberName,
		$MemberUPN,
		$MemberEnabled,
		$MemberDescription,
		$MemberDistinguishedName
	)
	$TableData = @"
	<!-- Table content: -->
	<tr>
		<td>$MemberName</td>
		<td>$MemberUPN</td>
		<td>$MemberEnabled</td>
		<td>$MemberDescription</td>
		<td>$MemberDistinguishedName</td>
	</tr>
"@
	Return $TableData
}
function EndTable {
	$EndTable = @"
	</table>
"@
	Return $EndTable
}
function EndDiv {
	$EndDiv = @"
	</div>
"@
	Return $EndDiv
}
function EndHTML {
	$EndHTML = @"
    <script>
        var coll = document.getElementsByClassName("collapsible");
        var i;
        for (i = 0; i < coll.length; i++) {
            coll[i].addEventListener("click", function () {
                this.classList.toggle("active");
                var content = this.nextElementSibling;
                if (content.style.display === "block") {
                    content.style.display = "none";
                } else {
                    content.style.display = "block";
                }
            });
        }
    </script>
</body>
</html>
"@
	Return $EndHTML
}

function GetReportNestedGroup {
	param (
		$NestedADGroup
	)
	foreach ($ADGroup in $NestedADGroup) {
		$members = Get-ADGroupMember $ADGroup | Sort-Object -Property objectClass -Descending
		$memberscount = (Get-ADGroupMember $ADGroup).distinguishedName.count
		StartCollapsibleTable -GroupName $ADGroup.Name -Description $ADGroup.Description -Totalamountofmembers $memberscount
		$MembersSpecial = $members | Where-Object { $_.objectClass -ne "user" -and $_.objectClass -ne "computer" -and $_.objectClass -ne "group" }
		$MembersUsers = $members | Where-Object { $_.objectClass -eq "user" }
		$MembersComputers = $members | Where-Object { $_.objectClass -eq "computer" }
		$MembersGroups = $members | Where-Object { $_.objectClass -eq "group" }
		foreach ($member in $MembersUsers) {
			$UserInfo = get-aduser $member -Properties DisplayName, UserPrincipalName, Enabled, Description, DistinguishedName | Select-Object DisplayName, UserPrincipalName, Enabled, Description, DistinguishedName
			TableData -MemberName $UserInfo.DisplayName -MemberUPN $UserInfo.UserPrincipalName -MemberEnabled $UserInfo.Enabled -MemberDescription $UserInfo.Description -MemberDistinguishedName $UserInfo.DistinguishedName		
		}
		foreach ($member in $MembersSpecial) {
			$Special = get-adobject -LDAPFilter "(objectSid=$($member.SID))" -Properties Name, SamAccountName, Description, DistinguishedName | Select-Object Name, SamAccountName, Description, DistinguishedName
			TableData -MemberName $Special.Name -MemberUPN $Special.SamAccountName -MemberEnabled "N/A" -MemberDescription $Special.Description -MemberDistinguishedName $Special.DistinguishedName	
		}
		foreach ($member in $MembersComputers) {
			$ComputerInfo = get-adcomputer $member -Properties Name, DNSHostName, Enabled, Description, DistinguishedName | Select-Object Name, DNSHostName, Enabled, Description, DistinguishedName
			TableData -MemberName $ComputerInfo.Name -MemberUPN $ComputerInfo.DNSHostName -MemberEnabled $ComputerInfo.Enabled -MemberDescription $ComputerInfo.Description -MemberDistinguishedName $ComputerInfo.DistinguishedName		
		}
		EndTable
		foreach ($member in $MembersGroups) {
			GetReportNestedGroup -NestedADGroup $member
		}
		EndDiv
		EndDiv
	}
}

function GetReport {
	param (
		$ADGroups
	)
	StartHTML -Totalamountofgroups $ADGroups.count
	foreach ($ADGroup in $ADGroups) {
		$members = Get-ADGroupMember $ADGroup | Sort-Object -Property objectClass -Descending
		$MembersSpecial = $members | Where-Object { $_.objectClass -ne "user" -and $_.objectClass -ne "computer" -and $_.objectClass -ne "group" }
		$MembersUsers = $members | Where-Object { $_.objectClass -eq "user" }
		$MembersGroups = $members | Where-Object { $_.objectClass -eq "group" }
		$MembersFirstCount = (Get-ADGroupMember $ADGroup).distinguishedName.count
		#$MembersFirstCount = (Get-ADGroupMember $ADGroup -Recursive | measure-object).count
		StartCollapsibleTable -GroupName $ADGroup.Name -Description $ADGroup.Description -Totalamountofmembers $MembersFirstCount

		foreach ($member in $MembersUsers) {
			$UserInfo = get-aduser $member -Properties DisplayName, UserPrincipalName, Enabled, Description, DistinguishedName | Select-Object DisplayName, UserPrincipalName, Enabled, Description, DistinguishedName
			TableData -MemberName $UserInfo.DisplayName -MemberUPN $UserInfo.UserPrincipalName -MemberEnabled $UserInfo.Enabled -MemberDescription $UserInfo.Description -MemberDistinguishedName $UserInfo.DistinguishedName
		}
		foreach ($member in $MembersSpecial) {
			$Special = get-adobject -LDAPFilter "(objectSid=$($member.SID))" -Properties Name, SamAccountName, Description, DistinguishedName | Select-Object Name, SamAccountName, Description, DistinguishedName
			TableData -MemberName $Special.Name -MemberUPN $Special.SamAccountName -MemberEnabled "N/A" -MemberDescription $Special.Description -MemberDistinguishedName $Special.DistinguishedName	
		}
		EndTable
		foreach ($member in $MembersGroups) {
			GetReportNestedGroup -NestedADGroup $member        
		}
		EndDiv
	}
	EndDiv
	EndHTML
}
$ReportADGroups = Get-adobject -filter 'ObjectClass -eq "group"' -Properties Name, member, Description, ObjectClass 
GetReport -ADGroups $ReportADGroups | out-file -FilePath C:\temp\Report.html