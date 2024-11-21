#This fuction will validate if a string variable is null or empty
function test-variable {
    param(
        [ValidateNotNullOrEmpty()]
        [string] $Variable
    )
    return $true
}