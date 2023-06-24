function Get-VMinfo {
    [CmdletBinding()]
    param(
    )
    begin {
        class vmsInfo {
            [string]$vmName
            [string]$configuredOS
            [string]$runningOS
            [string]$comment
            [string]$ip
            [string]$vlan
        } 
        $global:groupServersInfo = New-Object System.Collections.ArrayList

    }
    process {
        $vmInfo = get-vm
        foreach ($vm in $vmInfo) {
            $ServersInfo = [vmsInfo]::new()
            $ServersInfo.vmName = $vm.Name
            $ServersInfo.configuredOS = $vm.ExtensionData.Config.GuestFullName
            $ServersInfo.runningOS = $vm.Guest.OsFullName
            $ServersInfo.comment = $vm.ExtensionData.Config.Annotation
            $ServersInfo.ip = $vm.Guest.IPAddress[0]
            $ServersInfo.vlan = $vm | Get-NetworkAdapter | Select-Object -ExpandProperty NetworkName
            [void]$groupServersInfo.Add($ServersInfo)
        }
        $groupServersInfo
    }
    end {
        $groupServersInfo
    }
}
Get-VMinfo
