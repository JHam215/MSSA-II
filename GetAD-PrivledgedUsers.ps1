# This funtion will return all users with elevated privledges in a Domain
function GetAD-PrivledgedUsers {
    [CmdletBinding()]
    Param (
        [string]$Domain, 
        [string]$OutputLocal
    )
    BEGIN { 
        # Import the ActiveDirectory module
        Try { Import-Module ActiveDirectory -ErrorAction Stop }
        Catch { Write-Host "Unable to load Active Directory module, is RSAT installed?"; Break }
        $Results = @()
       
        # Define the privileged groups to check
        $privilegedGroups = @(
            "Domain Admins",
            "Enterprise Admins",
            "Schema Admins",
            "Administrators",
            "Account Operators"
        )

        #if output is supposed to go to a file, initialize that file.
        $OutputToFile = $false
        $ReportDate = Get-Date -format "yyyy-MMM-dd"
        if (-not [string]::IsNullOrEmpty($OutputLocal)){
            Write-Host "Output local is specified " $OutputLocal 
            $OutputToFile = $true
            New-Item -Path $OutputLocal -ItemType File -Force
            "                Privledged User Report                   ", $ReportDate | Add-Content -Path $OutputLocal
            "User Name         /     Group" | Add-Content -Path $OutputLocal
            "---------------         ------------" | Add-Content -Path $OutputLocal
        } 
        else {
            <# write to screen #>
            Write-Output "output only to screen"
        }
    }
    PROCESS {
        # Iterate over each privileged group
        foreach ($group in $privilegedGroups) {
            # Get the members of the group
            $members = Get-ADGroupMember -Identity $group

            # Output the members of the group
            foreach ($member in $members) {
                # Check if the member is a user
                if ($member.ObjectClass -eq "user") {
                    if ($OutputToFile -eq $true) {
                        # Apend the user's datails to file
                        $member.Name + "   /   " + $group | Add-Content -Path $OutputLocal
                    }
                    else {
                        # Output the user's details to screen
                        Write-Output "User: $($member.Name) Group: $group"
                        Write-Output "-------------------------"
                    } 
                }
            }
        }
        # search servers for admin users
        $DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
        ForEach ($Server in (Get-ADComputer -Filter { OperatingSystem -like "*Server*" } -Properties OperatingSystem))
        {	If ($DCs -contains $Server.Name)
            {	Continue
            }
            ForEach ($Part in (Get-CimInstance Win32_GroupUser -ComputerName $Server.Name | Where-Object { $_ -like "*Administrators*" }))
            {	$User = $Part.PartComponent.Split("=")[2].Replace("`"","")
                If ($User -eq "Administrator" -or $User -eq "Domain Admins")
                {	Continue
                }
                Else
                {	$Results += New-Object PSObject -Property @{
                        Server = $Server.Name
                        User = $User
                        Domain = $Part.PartComponent.Split("=")[1].Split(",")[0].Replace("`"","")
                    }
                }
            }
        }
    }
    END {
        $Results
    }   
}