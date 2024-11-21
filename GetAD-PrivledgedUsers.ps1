# This funtion will return all users with elevated privledges in a Domain
function GetAD-PrivledgedUsers {
    [CmdletBinding()]
    Param (
        [Parameter(position = 0, Mandatory=$false, ValueFromPipeline=$true)]
        [string[]]$Domain, 
        [Parameter(position = 1, Mandatory=$false, ValueFromPipeline=$true)]
        [string[]]$OutputLocal
    )
    BEGIN { 
        # Import the ActiveDirectory module
        Try { Import-Module ActiveDirectory -ErrorAction Stop }
        Catch { Write-Host "Unable to load Active Directory module, is RSAT installed?"; Break }
        $Results = @()
        $file = "User / Group"

        # Define the privileged groups to check
        $privilegedGroups = @(
            "Domain Admins",
            "Enterprise Admins",
            "Schema Admins",
            "Administrators",
            "Account Operators"
        )
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
                    # Output the user's details
                    Write-Output "User: $($member.Name)"
                    Write-Output "Group: $group"
                    Write-Output "-------------------------"
                    $File += $($member.Name), " / ", $group 
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
        #Output to screen or to file
        if (-not [string]::IsNullOrEmpty($OutputLocal)){
            Write-Output "Output local is specified for output file"
            "$File" | Out-File -FilePath $OutputLocal 
        } 
        else {
            <# write to screen #>
            Write-Output "output only to screen"
            $Results
        }
    }   
}

