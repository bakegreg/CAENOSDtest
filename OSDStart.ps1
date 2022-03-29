Param(
    [Parameter(Mandatory=$True)][string]$RepositoryZipFileUrl,
    [Parameter(Mandatory=$True)][string]$JsonFileName,
    [Parameter(Mandatory=$True)][string]$DownloadLocation  
)

#Connect to task sequence environment
#$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

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

#read in json, etc...
$json = Get-Content -Raw -Path (join-path -path $DownloadLocation -ChildPath $JsonFileName) | ConvertFrom-Json
foreach ($entry in $json.entries){
    #$computerName = $tsenv.Value("CAENComputerName")
    $computerName = "caen-hanzo"
    if (($entry.ComputerNameString -eq "All") -or ($computerName -like $entry.ComputerNameString)){
        start-process -filepath (join-path $RepositoryZipFileUrl -ChildPath $entry.script) -ArgumentList $entry.ArgumentList -NoNewWindow -Wait
    }
}