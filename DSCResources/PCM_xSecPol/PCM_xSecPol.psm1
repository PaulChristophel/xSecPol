function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UserSID,
        
        [ValidateSet("Batch","Service","Network","")]
        [System.String]
        $PrivilegeRight
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    if ($PrivilegeRight -eq "Batch")
    {
        $LogonRightName = "SeBatchLogonRight"
    }
    elseif ($PrivilegeRight -eq "Service")
    {
        $LogonRightName = "SeServiceLogonRight"
    }
    else
    {
        throw
    }
    
    $tmp = [System.IO.Path]::GetTempFileName()
    secedit.exe /export /cfg $tmp
    $content = Get-Content -Path $tmp
    Remove-Item $tmp
    
    $LogonRightString = $content | ? { $_.Contains($LogonRightName) }
    $currentSetting = $LogonRightString.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)[1].Trim()
    
    $UserSidPresent = $currentSetting -split ',' | select-string -SimpleMatch "$UserSID" -Quiet

    
    return @{ "UserSidPresent" = $UserSidPresent }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UserSID,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [ValidateSet("Batch","Service")]
        [System.String]
        $PrivilegeRight
    )

    if ($PrivilegeRight -eq "Batch")
    {
        $LogonRightName = "SeBatchLogonRight"
    }
    elseif ($PrivilegeRight -eq "Service")
    {
        $LogonRightName = "SeServiceLogonRight"
    }
    
    $tmp = [System.IO.Path]::GetTempFileName()
    secedit.exe /export /cfg $tmp
    $content = Get-Content -Path $tmp

    $LogonRightString = $content | ? { $_.Contains("$LogonRightName") }
    $currentSetting = $LogonRightString.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)[1].Trim()

    if ($Ensure -eq "Present")
    {
        if( $currentSetting -split ',' | select-string -SimpleMatch $UserSID -NotMatch -Quiet )
        {
            $currentSetting = "*$($UserSID),$($currentSetting)"
            $currentSetting = $currentSetting.Trim(',')

            $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$LogonRightName = $currentSetting
"@
        }
    }
    else
    {
        if( $currentSetting -split ',' | select-string -SimpleMatch $UserSID -Quiet )
        {
            $currentSetting = $($currentSetting -split ',' | select-string -SimpleMatch $UserSID -NotMatch) -join ','
            $currentSetting = $currentSetting.Trim(',')

            $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$LogonRightName = $currentSetting
"@
        }
    }
    if ($outfile)
    {
        $tmp2 = [System.IO.Path]::GetTempFileName()
        $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
        Write-Debug $outfile
        Write-Verbose "Granting UserSID $UserSID access to $LogonRightName"
        secedit.exe /configure /db "secedit.sdb" /cfg $tmp2 /areas USER_RIGHTS
        try
        {
            Write-Debug "Removing temporary files"
            Remove-Item $tmp
            Remove-Item $tmp2
        }
        catch
        {
            Write-Debug "No temp files to remove"
        }
    }

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UserSID,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("Batch","Service")]
        [System.String]
        $PrivilegeRight
    )

    $TargetResourceSetting = Get-TargetResource -UserSID $UserSID -PrivilegeRight $PrivilegeRight
    
    if ($Ensure -eq "Present")
    {
        if ($TargetResourceSetting.UserSidPresent)
        {
            Write-Verbose "Compliant: UserSID $UserSID is present. Ensure is set to $Ensure"
            $Result = $True
        }
        else
        {
            Write-Verbose "Not Compliant: UserSID $UserSID is not present. Ensure is set to $Ensure"
            $Result = $False
        }
    }
    else
    {
        if ($TargetResourceSetting.UserSidPresent)
        {
            Write-Verbose "Not Compliant: UserSID $UserSID is present. Ensure is set to $Ensure"
            $Result = $False
        }
        else
        {
            Write-Verbose "Compliant: UserSID $UserSID is not present. Ensure is set to $Ensure"
            $Result = $True
        }
    }

    return $Result
}


Export-ModuleMember -Function *-TargetResource

