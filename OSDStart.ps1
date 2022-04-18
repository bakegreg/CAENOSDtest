Param(
    [Parameter(Mandatory=$True)][string]$RepositoryZipFileUrl,
    [Parameter(Mandatory=$True)][string]$JsonFileName,
    [Parameter(Mandatory=$True)][string]$DownloadLocation,
    [int]$ALLOWEDSCRIPTRUNTIME = 900 #seconds
)

#Connect to task sequence environment
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

#verify downloadlocationroot exists
if (-not(test-path $DownloadLocation)){
    new-item $DownloadLocation -ItemType Directory -Confirm:$false
}

#download zip file, expand, and cleanup
$zipFile = join-path -path $DownloadLocation -ChildPath zip.zip
new-item $zipFile -ItemType File -Force
Invoke-RestMethod -Uri $RepositoryZipFileUrl -OutFile $ZipFile
Expand-Archive -path $zipFile -DestinationPath $DownloadLocation -Force
Remove-item -path $zipFile -Force
$DownloadLocation = (get-childitem $DownloadLocation).FullName

#close the TS UI temporarily
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

#read in json and process scripts
$json = Get-Content -Raw -Path (join-path -path $DownloadLocation -ChildPath $JsonFileName) | ConvertFrom-Json
foreach ($entry in $json.entries){
    $computerName = $tsenv.Value("CAENComputerName")
    #$computerName = "caen-hanzo" ----FOR TESTING OUTSIDE A TS
    $filepath = join-path $DownloadLocation -ChildPath $entry.script
    if ($entry.argumentList){
        $filepath = $filepath + " $($entry.argumentlist)"
    }
    write-output "Computer Name [$ComputerName]"
    write-output "Name string to match against [$($entry.ComputerNameString)]"
    write-output "Script [$($entry.script)]"
    write-output "Arguments [$($entry.argumentList)]"
    if (($entry.ComputerNameString -eq "All") -or ($computerName -like $entry.ComputerNameString)){
        write-output "Running [powershell.exe -executionpolicy bypass -file $($filepath)]."
        $processid = (start-process -nonewwindow -passthru -filepath "powershell.exe" -argumentList "-executionpolicy bypass -file $filepath").Id
        $starttime = get-date
        do{
            start-sleep -seconds 2
            $currenttime = get-date
            if (($currenttime - $starttime).totalseconds -gt $ALLOWEDSCRIPTRUNTIME){
                write-output "Script runtime of [ $ALLOWEDSCRIPTRUNTIME ] exceeded. Ending it now."
                Get-Process -Id $processid | Select-Object -Property Id | ForEach-Object -Process { Stop-Process -Id $_.Id -Force }
            }
        } while ((get-process -Id $processid -ErrorAction Ignore) -and (($currenttime - $starttime).totalseconds -le $ALLOWEDSCRIPTRUNTIME))
        write-output "[$($entry.script)] completed."
    }
    else{
        write-output "Skipping [$($entry.script)]"
    }
}
write-output "All scripts from [$jsonFileName] have been processed. Exiting."