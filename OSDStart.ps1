Param(
    [Parameter(Mandatory=$True)][string]$RepositoryZipFileUrl,
    [Parameter(Mandatory=$True)][string]$JsonFileName,
    [Parameter(Mandatory=$True)][string]$DownloadLocation  
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

#read in json, etc...
$json = Get-Content -Raw -Path (join-path -path $DownloadLocation -ChildPath $JsonFileName) | ConvertFrom-Json
foreach ($entry in $json.entries){
    $computerName = $tsenv.Value("CAENComputerName")
    #$computerName = "me-hanzo"
    $filepath = join-path $DownloadLocation -ChildPath $entry.script
    if ($entry.argumentList){
        $filepath = $filepath + " $($entry.argumentlist)"
    }
    write-output "Computer Name [$ComputerName]"
    write-output "Name string to match against [$($entry.ComputerNameString)]"
    write-output "Script [$($entry.script)]"
    write-output "Arguments [$($entry.argumentList)]"
    if (($entry.ComputerNameString -eq "All") -or ($computerName -like $entry.ComputerNameString)){
        if ($entry.interactsWithTaskSequence.tolower() -eq "true"){
            $argumentlist = "-process:TSProgressUI.exe powershell.exe -noprofile -windowstyle hidden -executionpolicy bypass -file $filepath"
            write-output "Script interacts with the TS so running with ServiceUI.exe."
            write-output "The argument list is $argumentlist"
            $process = start-process -wait -nonewwindow -filepath "ServiceUI.exe" -argumentList $argumentlist
            write-output "[$($entry.script)] completed with exit code [$($process.exitcode)]"
        }
        write-output "Running [$($filepath)]."
        $process = start-process -wait -nonewwindow -filepath "powershell.exe" -argumentList "-executionpolicy bypass -file $filepath"
        write-output "[$($entry.script)] completed with exit code [$($process.exitcode)]."
    }
    else{
        write-output "Skipping [$($entry.script)]"
    }
}
write-output "All scripts from [$jsonFileName] have been processed. Exiting."