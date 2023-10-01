#Dynamic DNS Check for DNS Made Easy


#Improvements
#Log File Size Check = Length or line check followed by deleting or a file size check followed by deleting
#Add more detailed logs for troubleshooting (might not be worth it)

#Check if Log File Exist and create if it doesn't and Add Start time for script
[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls"

function Log-Message {
param (
    [string]$message
)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$timestamp - $message" | add-content -path $PSScriptRoot\log.log
}

if (-not (Test-Path -path $PSScriptRoot\log.log)) {
    New-item -path $PSScriptRoot -name "log.log" -ItemType "file" 
}

Log-Message "Starting Script..."
#A1:Check for Existance of Parameters.CSV
if (Test-Path -Path $PSScriptRoot\parameters.csv) {
    Log-Message "Parameter File does exist. Pulling Data..."
    $parameters = import-csv -path $PSScriptRoot\parameters.csv
    try {
        $url = (Invoke-WebRequest -UseBasicParsing -uri "http://ifconfig.me/ip").Content
    }
    catch {
        Log-Message $error
        Log-Message "Stopping Script"
        Exit
    }
    Log-Message "Checking if IP Changed."
    #B1: Check for IP Change
    if ($url -eq $parameters.ip) {
        Log-Message "IP has not changed. Ending Script..."
    }
    #B2: Check for IP Change
    else {
        Log-Message "IP has changed. Updating Record..."
        $parameters.ip = $url
        $parameters | export-csv -NoTypeInformation -path $PSScriptRoot\parameters.csv
        $result = (Invoke-WebRequest -UseBasicParsing -uri "https://cp.dnsmadeeasy.com/servlet/updateip?username=$($parameters.username)&password=$($parameters.password)&id=$($parameters.id)&ip=$($parameters.ip)").content
        Log-Message "DNS Made Easy Results: $result"
    }
}
#A2:Check for Existance of Parameters.CSV
else {
    write-host "file doesn't exist. Please enter Parameter Data..."
    $urihash = [PSCustomObject]@{
        username = read-host -prompt "Enter Username"
        password = read-host -prompt "Enter Record Password"
        id       = Read-host -prompt "Enter Record ID"
        ip       = (Invoke-WebRequest -UseBasicParsing -uri "https://ifconfig.me/ip").Content
    }
    $urihash | export-csv -NoTypeInformation -path $PSScriptRoot\parameters.csv
    write-host $urihash
    Log-Message "Updating IP. Ending Script..."
    $result = (Invoke-WebRequest -UseBasicParsing -uri "https://cp.dnsmadeeasy.com/servlet/updateip?username=$($parameters.username)&password=$($parameters.password)&id=$($parameters.id)&ip=$($parameters.ip)").content
    Log-Message "DNS Made Easy Results: $result"
}

