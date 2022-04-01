$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$ComputerName = $tsenv.Value("CAENComputerName")

#------------------------------Connect to Active Directory--------------------
import-module ActiveDirectory 3>$null
$user = $tsenv.Value("CaenAdUser")
$pw = $tsenv.Value("CaenAdPw")

#the key is supposed to be integers separated by newlines but SCCM variables can't handle the newlines. Used commas instead so the data needs to converted. Writes it to disk so it can be read in in as a byte string
$tsenv.Value("CaenAdPwKey") -replace ",","`n" | out-file .\key -encoding utf8 

$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, ($pw | get-content .\key)

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
		$validComputer = $True
	}
	elseif ($computerObject.distinguishedName -like "*OU=Engineering Base Desktop,OU=CAEN Managed Desktops,OU=CAEN,OU=ENGIN,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"){
		$tsenv.Value("CLSEBD") = "EBD"
		$validComputer = $True
	}
	else {
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("$ComputerName is not located in a valid EBD or CLSE Active Directory OU. Move the computer object or select a new computer name.", "Computer name prompt", "Example:  caen-testcomp")
	}
}

#------------------Set TS variables----------------------------
$tsenv.Value("DistinguishedName") = [string]$computerObject.distinguishedName
$tsenv.Value("OSDComputerName") = $ComputerName
$tsenv.Value("CAENComputerName") = $ComputerName

Set-Location x:
remove-psdrive umroot