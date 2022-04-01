$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

$ComputerName = $tsenv.Value("CAENComputerName")

#------------------------------Connect to Active Directory--------------------
import-module ActiveDirectory 3>$null
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($tsenv.Value("CaenAdUser")), ($tsenv.Value("CaenAdPw") | ConvertTo-SecureString -key ($tsenv.Value("CaenAdPwKey")))

#Try connecting to AD
$retries = 0

while ($retries -lt 3) {
	new-psdrive -PSProvider ActiveDirectory -Name umroot -Server "adsroot.itcs.umich.edu" -root "//RootDSE/OU=Engin,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu" -credential $credential
	if ($?){ #if the command succeeded stop looping
		$retries = 3
	}
	else {
		$retries += 1
		if ($retries -eq 3){
			$tsenv.Value("DistinguishedName") = "Unable to connect to AD"
			return 1338 #Cancel the Task Sequence with this error code
		}
		else {
			Write-error "Error: Cannot connect to active directory on attempt $retries. Retrying."
		}
		start-sleep 5
	}
}
# Close the TS UI temporarily
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()


#-------------------------Check AD for Computer Object and prompt if required----------------------
Set-Location umroot:

$validComputer = $False
while (-not($validComputer)){
	$computerObject = Get-ChildItem -recurse | Where-Object {$_.Name -eq $ComputerName}
	if ($ComputerName -like "MININT-*"){
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the computer name", "Computer name prompt", "Example: caen-testcomp")
	}
	elseif ($ComputerName.length -eq 0) { 
		#This would happen if they clicked Cancel
		Set-Location x:
		remove-psdrive umroot
		return 1337 #Cancel the Task Sequence with this error code
	}
	elseif (!$computerObject){
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("$ComputerName was not found nested under the Engin OU. Create the object or enter a new computer name.", "Computer name prompt", "Example:  caen-testcomp")
	}
	elseif ($computerObject.distinguishedName -like "*OU=CAEN Lab Software Environment,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"){
		$tsenv.Value("CLSEBD") = "CLSE"
		$Product = "CLSE"
		$validComputer = $True
	}
	elseif ($computerObject.distinguishedName -like "*OU=Engineering Base Desktop,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"){
		$tsenv.Value("CLSEBD") = "EBD"
		$Product = "EBD"
		$validComputer = $True
	}
	else {
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("$ComputerName is not located in a valid EBD or CLSE Active Directory OU. Move the computer object or select a new computer name.", "Computer name prompt", "Example:  caen-testcomp")
	}
}

#------------------Set TS variables and display summary to user----------------------------
$tsenv.Value("DistinguishedName") = [string]$computerObject.distinguishedName
$tsenv.Value("OSDComputerName") = $ComputerName
$tsenv.Value("CAENComputerName") = $ComputerName

#display message box showing the product to be installed
$Version = $tsenv.Value("CAEN_VERSION")
if ($tsenv.Value("ZTILinux") -eq "true"){
	$Product = $Product + " - Dual Boot Linux"
}
else{
	$Product = $Product + " - Single Boot Windows"
}
$Model = Get-WmiObject Win32_Computersystem | foreach-object {$_.Model}
$Message = "The product to install has been dynamically selected based on the Active Directory OU of the computer object. Summary: `n`nProduct:                   $product`nVersion:                   $Version`nComputer Name:   $ComputerName `nModel:                     $Model`n`nThis box will automatically close in two minutes." 

$SecondsToWait = 120 #amount of time before the box automatically closes
$Title = "CAEN Product Summary"
$Button = 0 #a single OK button (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
$Icon = 64 #an Information icon

(New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)

Set-Location x:
remove-psdrive umroot



