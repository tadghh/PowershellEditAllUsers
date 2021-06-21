# Credit to : https://www.pdq.com/blog/modifying-the-registry-of-another-user/
# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} |
        Select  @{name="SID";expression={$_.PSChildName}},
        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
        @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}

# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object {$_.PSChildname -match $PatternSID} | Select-Object @{name="SID";expression={$_.PSChildName}}

# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username

# Loop through each profile on the machine
Foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    IF ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
    
    #Your changes should go here!
    #Changes all users scrollbars to be 13px thick
    Set-ItemProperty registry::HKEY_USERS\$($Item.SID )\"Control Panel"\Desktop\WindowMetrics\ -Name ScrollHeight -Value (-165) -Type String
    Set-ItemProperty registry::HKEY_USERS\$( $Item.SID)\"Control Panel"\Desktop\WindowMetrics\ -Name ScrollWidth -Value (-165) -Type String
    Get-ItemProperty registry::HKEY_USERS\$( $Item.SID )\"Control Panel"\Desktop\WindowMetrics\
    Write-Host $Item.SID
    #####################################################################

    # Unload ntuser.dat
    IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}
