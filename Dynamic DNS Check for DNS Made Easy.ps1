#Dynamic DNS Check for DNS Made Easy


#Improvements
#Log File Size Check = Length or line check followed by deleting or a file size check followed by deleting
#Add more detailed logs for troubleshooting (might not be worth it)

#Check if Log File Exist and create if it doesn't and Add Start time for script
[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls"
$date = Get-Date
if (Test-Path -path $PSScriptRoot\log.log) {
    add-content -path $PSScriptRoot\log.log -Value "$date - Starting Script..."
}
else {
    New-item -path $PSScriptRoot -name "log.log" -ItemType "file" -Value "$date - Starting Script"
}

#A1:Check for Existance of Parameters.CSV
if (Test-Path -Path $PSScriptRoot\parameters.csv) {
    add-content -path $PSScriptRoot\log.log -Value "Parameter File does exist. Pulling Data..."
    $parameters = import-csv -path $PSScriptRoot\parameters.csv
    try {
        $url = (Invoke-WebRequest -UseBasicParsing -uri "http://ifconfig.me/ip").Content
    }
    catch {
        add-content -path $PSScriptRoot\log.log -Value $error
        add-content -path $PSScriptRoot\log.log -Value "Stopping Script"
        Exit
    }
    add-content -path $PSScriptRoot\log.log -Value "Checking if IP Changed."
    #B1: Check for IP Change
    if ($url -eq $parameters.ip) {
        add-content -path $PSScriptRoot\log.log -Value "IP has not changed. Ending Script..."
    }
    #B2: Check for IP Change
    else {
        add-content -path $PSScriptRoot\log.log -Value "IP has changed. Updating Record..."
        $parameters.ip = $url
        $parameters | export-csv -NoTypeInformation -path $PSScriptRoot\parameters.csv
        $result = (Invoke-WebRequest -UseBasicParsing -uri "https://cp.dnsmadeeasy.com/servlet/updateip?username=$($parameters.username)&password=$($parameters.password)&id=$($parameters.id)&ip=$($parameters.ip)").content
        add-content -path $PSScriptRoot\log.log -Value "DNS Made Easy Results: $result"
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
    add-content -path $PSScriptRoot\log.log -Value "Updating IP. Ending Script..."
    $result = (Invoke-WebRequest -UseBasicParsing -uri "https://cp.dnsmadeeasy.com/servlet/updateip?username=$($parameters.username)&password=$($parameters.password)&id=$($parameters.id)&ip=$($parameters.ip)").content
    add-content -path $PSScriptRoot\log.log -Value "DNS Made Easy Results: $result"
}

