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
        }
    }
}
# A method to search servers for admin users
$DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
ForEach ($Server in (Get-ADComputer -Filter { OperatingSystem -like "*Server*" } -Properties OperatingSystem))
{	If ($DCs -contains $Server.Name)
	{	Continue
	}
	ForEach ($Part in (Get-WmiObject Win32_GroupUser -ComputerName $Server.Name | Where-Object { $_ -like "*Administrators*" }))
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
$Results

# Another Method to serch each computer for local admin
#
#additional changes to try to get options to comit
why will this not upload?

