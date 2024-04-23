function Get-FormattedDate{
    return Get-Date -Format "MMMMM dd, yyyy 'at' hh:mmtt"
}

#return simple date (yyyymmdd) as string
function Get-SimpleDate{
    $date = Get-Date
    return $date.ToString("yyyyMMdd")
}

#check if two dates are different
function Compare-Dates{
    param(
        [Parameter(Mandatory = $true)]
        [String]$simpleDate
    )
    $currentSimpleDate = Get-SimpleDate

    if($simpleDate -ne $currentSimpleDate){return $false}
    else {return $true}
}

#list is empty
#sleep until date changes, then break 
function Check-NewDay{
    param(
        [Parameter(Mandatory = $true)]
        [String]$simpleDate
    )

    $dateCheckSleepTime = 1800 #half hour

    Write-Host "$(Get-FormattedDate): List empty, checking if it's a new day."
    while($true){
        if(Compare-Dates -simpleDate $simpleDate){
            Write-Host "$(Get-FormattedDate): Not a new date yet, sleeping for $dateCheckSleepTime seconds..."
            Start-Sleep -Seconds $dateCheckSleepTime #pause for number of seconds
        } else {
            Write-Host "$(Get-FormattedDate): It's a new day ($(Get-SimpleDate))"
            Break
        }        
    }
}

#job checker, has flag for continuous mode
function Check-Jobs{
    param([boolean]$Continuous)

    $jobs = Get-Job

    if($Continuous){
        $jobs = Get-Job
        while($jobs.Count -gt 0){
            #make sure $completedJobs variable is not null before working on it
            if($completedJobs = Get-Job -State Completed){
                Receive-Job $completedJobs 
                Remove-Job $completedJobs
            }
        Start-Sleep -Seconds 5
        $jobs = Get-Job
        }
    Write-Host "$(Get-FormattedDate): All jobs finished"    
    } else {
        if($jobs.Count -gt 0){
            #make sure $completedJobs variable is not null before working on it
            if($completedJobs = Get-Job -State Completed){
                Receive-Job $completedJobs 
                Remove-Job $completedJobs
            }
        }
    } 
}

#query nexthink for all computers which haven't had updates for 16-36 days
function Get-NoWinUpdatesBetween16_36Days{
    #run and return the query
    $winUpdateList = Invoke-Nxql -ServerName '<Server IP or Name here>' `
    -UserName $credentials.UserName `
    -UserPassword $credentials.Password `
    -Query "(select (name)
            (from device
            (where device
            (ge number_of_days_since_last_windows_update (integer 15))
            (le number_of_days_since_last_windows_update (integer 36)))))" 
    return $winUpdateList[1]
}

#query nexthink for all computers with non-compliant update status
function Get-WinUpdateNonCompliantList{
    #run and return the query
    $winUpdateList = Invoke-Nxql -ServerName '<Server IP or Name here>' `
    -UserName $credentials.UserName `
    -UserPassword $credentials.Password `
    -Query "(select (name)
            (from device 
            (where device 
            (eq #'Devices - OS - Compliance OS Update' (enum noncompliant)))))" 
    return $winUpdateList[1]
}


#return arraylist for all computers which haven't had updates for 16-36 days
function Make-NoWinUpdatesBetween16_36DaysList{
    Write-Host "$(Get-FormattedDate): Creating ArrayList of computers not updated for 16-36 days."
    #query raw list then trim beginning and ends
    $nonCompliant = Get-NoWinUpdatesBetween16_36Days
    [System.Collections.ArrayList]$dataAsArrayList = @($nonCompliant.Split([Environment]::NewLine) | Select-Object -Skip 1 | Select-Object -SkipLast 1)
    return $dataAsArrayList
}

#return arraylist with all computers with non-compliant update status
function Make-WindowsUpdatesArrayList{
    Write-Host "$(Get-FormattedDate): Creating ArrayList of computers with non-compliant Windows updates."
    #query raw list then trim beginning and ends
    $nonCompliant = Get-WinUpdateNonCompliantList
    [System.Collections.ArrayList]$dataAsArrayList = @($nonCompliant.Split([Environment]::NewLine) | Select-Object -Skip 1 | Select-Object -SkipLast 1)
    return $dataAsArrayList
}

#stop any previously running transcripts and start new transcript
function Start-CustomTranscript{
    $logDate = Get-Date -Format "yyyyMMdd"

    try{
        $count = 0
        while($true){
            Stop-Transcript
            $count++
        }
    } catch {
        Write-Host "Stopped $count transcripts."
    }
    Start-Transcript -Path C:\logs\winAutoUpdateList_$logDate.txt -Append
}


function Run-Checker{
    $sleepTime = 300
    $powershell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $dateCheckSleepTime = 1800 #half hour
    $referenceDate = Get-SimpleDate

    #creating an array list so we're able to resize array later
    [System.Collections.ArrayList]$computerNames = @(Make-WindowsUpdatesArrayList)
    $computerNames += @(Make-NoWinUpdatesBetween16_36DaysList)
    Write-Host "$(Get-FormattedDate): Today's list:"
    foreach($computer in $computerNames){Write-Host $computer}

    #loop until all names are gone
    while($computerNames.Count -ne 0){
        #loop through all available names
        foreach($computerName in $computerNames.ToArray()){
            #test if computer is online
            Write-Host "$(Get-FormattedDate): Checking if $computerName is online..."
            $isOnline = Test-Connection -count 2 -ComputerName $computerName -Quiet
            #if online, do task
            if($isOnline){
                Write-Host "$(Get-FormattedDate): $computerName is online on $(Get-FormattedDate)"            
                Start-Job -ScriptBlock{
                psexec -s "\\$using:computerName" $using:powershell "&{set-executionpolicy remotesigned; `
                            & '<Script Path or Command>'}"
                            #enter script path or command above 
                }      
                #after attempt, remove name
                Write-Host "$(Get-FormattedDate): Removing $computerName from list."
                $computerNames.Remove($computerName)
            }
        }
        #if it's the same date, sleep, otherwise break to restart checker
        if($referenceDate -eq (Get-SimpleDate)){
            Check-Jobs
            Write-Host "$(Get-FormattedDate): Sleeping for $sleepTime seconds..."
            Start-Sleep -Seconds $sleepTime #pause for number of seconds
        } else {
            Check-Jobs
            Start-Sleep -Seconds 600 #pause for 10 minutes in case we're right at midnight, give server chance to refresh 
            Write-Host "$(Get-FormattedDate): It's a new date ($(get-simpleDate)), restarting checker."
            Return 
        }
    }
    #list is empty, go to Check-NewDay function until new day comes along
    Check-NewDay -simpleDate $referenceDate
    Return
}


#try to execute script which queries nexthink
try{
    Write-Host "$(Get-FormattedDate): Executing Code-For-Invoke-Nxql.ps1"
    . \\mytfs01\public\IT\alex\scripts\Code-For-Invoke-Nxql.ps1
} catch {
    throw "$(Get-FormattedDate): Executing Code-For-Invoke-Nxql.ps1 failed. Stopping script."
}

#get creds for the session
$credentials = Get-Credential

#main loop
while($true){
    Start-CustomTranscript
    Run-Checker
}

