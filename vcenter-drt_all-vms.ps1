### BEGIN INI CONFIGURATION

$iniDir = ".\"
$iniFile = "ro_config.ini"
$iniPath = Join-Path -Path $iniDir -ChildPath $iniFile

# Check if the INI file exists
if (Test-Path $iniPath) {
    $iniFilePath = $iniPath
} else {
    Write-Host "ERROR: Configuration INI file not found at $iniPath."
    Exit
}

# Function to parse INI file
function Parse-IniFile ($filePath) {
    $iniContent = Get-Content -Path $filePath
    $iniData = @{}

    foreach ($line in $iniContent) {
        # Skip comment lines and empty lines
        if (-not ($line -match '^\s*;') -and $line -match '^\s*([^=]+?)\s*=\s*(.+)') {
            $iniData[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    return $iniData
}

# Parse INI file
$iniData = Parse-IniFile -filePath $iniFilePath

# Check if required parameters exist in the INI file
if (-not ($iniData.ContainsKey("vCenter_Host") -and $iniData.ContainsKey("vCenter_User") -and $iniData.ContainsKey("vCenter_Password"))) {
    Write-Host "ERROR: Missing vCenter_Host, vCenter_User, or vCenter_Password in the INI file."
    Exit
}

# Assign values from INI file
$vCenter_Host = $iniData["vCenter_Host"]
$vCenter_User = $iniData["vCenter_User"]
$vCenter_Password = $iniData["vCenter_Password"]


### VCENTER CONNECTION AND CONFIGURATION
Connect-VIServer -Server $vCenter_Host -User $vCenter_User -Password $vCenter_Password -ErrorAction Stop

# Check if VMware.PowerCLI module is installed
$powerCLIInstalled = Get-Module -Name VMware.PowerCLI -ListAvailable
Write-Host "REQUISITE CHECK: The VMware.PowerCLI Module is already installed."

if (-not $powerCLIInstalled) {
    # Install VMware.PowerCLI module
    Write-Host "REQUISITE CHECK: Required module VMware.PowerCLI not installed, installing now..."
    Install-Module -Force -Name VMware.PowerCLI -Scope CurrentUser -AllowClobber
}

# Suppress CEIP and invalid SSL certificate warnings
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null


### CSV CONFIGURATION
# Extract substring before the first dot to use as the vCenter host name
$vCenter_Host_Name = $vCenter_Host.Split('.')[0]

# Construct CSV file path using the extracted vCenter host name
$csvFilePath = Join-Path -Path ".\" -ChildPath "all-vms_report-$vCenter_Host_Name.csv"


### BEGIN

$Report = @()

# Use case: Retrieve all VMs
$VMs = Get-VM

# Alternative use case: Exclude VMs based on their names:
# $VMs = Get-VM | Where-Object {
#    ($_.Name -notlike "Network Extension Appliance*") -and
#    ($_.Name -notlike "VMware_Cloud_Director_Container_Service_Extension*")
# }

foreach ($VM in $VMs) {

    $row = "" | Select-Object VMName, Powerstate, ResourcePool, Folder

    $row.VMName = $VM.Name
    $row.Powerstate = $VM.Powerstate
    $row.ResourcePool = $VM.ResourcePool.Name
    $row.Folder = $VM.Folder.Name

    $Report += $row

    # Output to CSV, overwrite if existing
    $Report | Sort-Object VMName | Export-Csv -Path $csvFilePath -NoTypeInformation -UseCulture -Force

}

Disconnect-VIServer -Server $vCenter_Host -Confirm:$false
Write-Host "Elaboration complete, disconnected from vCenter and report saved to $csvFilePath"

# DEBUG: Print report to output
# $Report | Sort-Object VMName | Select-Object VMName, Powerstate, ResourcePool, Folder | Format-Table -AutoSize
