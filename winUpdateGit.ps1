$logDate = Get-Date -Format 'yyyyMMdd'
Start-Transcript -Path "C:\Logs\$logDate`_WinUpdate.txt" -Append #local copy of transcript

Set-ExecutionPolicy RemoteSigned -Force

if(!(Get-Module -Name PSWindowsUpdate)){
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module PSWindowsUpdate -force  
}
Import-Module PSWindowsUpdate -PassThru
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -ignorereboot -Verbose -ForceDownload -ForceInstall

Stop-Transcript 
