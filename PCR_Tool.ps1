#variables
$break = ""


$Repeat = $True
While ($Repeat)
{
#Ask User what they are wanting to do
$export = New-Object System.Management.Automation.Host.ChoiceDescription '&Export List of Network Drives', 'Export a list of network drives that are mapped on a remote computer.'
$import = New-Object System.Management.Automation.Host.ChoiceDescription '&Import and Map List of Network Drives', 'Choose to manually enter the network path you want to map to a drive.'
$softwareList = New-Object System.Management.Automation.Host.ChoiceDescription '&Retrieve List of Installed Software', 'Get a list of all installed software with version numbers from a remote computer.'
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($export, $import, $softwareList)
$title = "***PCR Tool***"
$message = 'Please choose a service from the list below:'
$result = $Host.UI.PromptForChoice($title, $message, $choices, 0)
$break

#Launch Tools
switch ($result) {
    0 { 
        #Get Remote PC Name
        $userName = Read-Host -Prompt "Enter LanID: "
        #$password = Read-Host -Prompt "Enter password: "
        $pcName = Read-Host -Prompt "Enter Name of Remote PC: "
        C:\Users\admin_wminc001\PsExec.exe \\$pcName -u USCAD\$userName  /accepteula /c C:\Users\Public\ExportNetworkDrives.ps1
        
    }
    1{
        #Get Remote PC Name
        $pcName = Read-Host -Prompt "Enter Name of Remote PC: "

        # Define array to hold identified mapped drives.
        $mappedDrives = @()

        # Import drive list.
        $mappedDrives = Import-Csv \\int.usc.local\users\home\wminc001\mappedDrives.csv

        # Iterate over the drives in the list.
        foreach ($drive in $mappedDrives) {
            # Create a new mapped drive for this entry.
            New-PSDrive -Name $drive.Name -PSProvider "FileSystem" -Root $drive.DisplayRoot -Persist -ErrorAction Continue 
        } 
    }
    2{
        #Get name of Remote PC with installed apps
        $pcName = Read-Host -Prompt "Enter Name of Remote PC: "

        #Get List of Applications installed on specified PC
        $appList = Get-WmiObject Win32_Product -ComputerName $pcName | Select-Object Name,Version

        #Get List of Applications installed on Local PC
        $localAppList = Get-WmiObject Win32_Product | Select-Object Name,Version
        
        #Create Folder
        $ErrorActionPreference = "Stop"
        try {
            New-Item -Path "C:\" -Name "PCR Tool Logs" -ItemType "directory"
            $break
            $break
        }
        catch  
        {
            Write-Output "Processing..."
            $break
        }
        
        #Create CSV of Apps installed on Remote PC 
        $appList | Export-CSV -Path "C:\PCR Tool Logs\appList.csv"

        #Create CSV of Apps installed on Local PC
        $localAppList | Export-CSV -Path "C:\PCR Tool Logs\localAppList.csv"

        #Create Compare Objects
        $file1 = Import-Csv -Path "C:\PCR Tool Logs\appList.csv"
        $file2 = Import-Csv -Path "C:\PCR Tool Logs\localAppList.csv"

        #Compare CSVs against each other
        Compare-Object -ReferenceObject $file1 -DifferenceObject $file2 -Property Name -IncludeEqual | Export-CSV -Path "C:\PCR Tool Logs\Apps.csv"

        #Create sorted CSV for Apps that are missing from Local PC
        $csv = Import-CSV "C:\PCR Tool Logs\Apps.csv" 
        $csv | Where-Object { $_.SideIndicator -eq '<=' } | export-csv "C:\PCR Tool Logs\neededApps.csv" -NoTypeInformation

        #Show CSV with the sorted items
        Invoke-Item "C:\PCR Tool Logs\neededApps.csv"
    }
    
}

#Ask user if they want to use any other services
$yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Choose to map your F Drive'
$no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Choose to manually enter the network path you want to map to a drive.'
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "***PCR Tool***"
$message = 'Would you like to run another service?'
$answer = $Host.UI.PromptForChoice($title, $message, $choices, 0)
$break

If ($answer -eq 1)
{
$Repeat = $False
}
}