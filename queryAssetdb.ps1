Param([Parameter(Mandatory=$True)][string]$URL)

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv.Value("ZTILinux") = "false"
$MACs = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | where IpEnabled -eq "True" | ForEach-Object {$_.MacAddress}
foreach ($MAC in $MACs){
	$fullURL = $URL + $MAC
	add-content -Path $env:temp\assetdbquery.log -Value $fullURL -Force
	$data = invoke-webrequest $fullURL -UseBasicParsing | convertfrom-json
	add-content -Path $env:temp\assetdbquery.log -Value $data -Force
	if ($data.results -eq "True"){
		$tsenv.Value("ZTILinux") = "true"
	}
}

	
