$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

#------------------Set Default Values-------------------------
$Timeout = 1800 #in seconds
$Message = "The task sequence was canceled. Click OK to continue." 
$Title = "CAEN Message"
$Icon = 64 #Information Icon
$Button = 0 #Single OK button

#------------------Set Values from TS Variables---------------
if ($tsenv.Value("CAENTimeout") -ne ""){
	$Timeout = [int]$tsenv.Value("CAENTimeout")
	$tsenv.Value("CAENTimeout") = ""
}
if ($tsenv.Value("CAENMessage") -ne ""){
	$Message = [string]$tsenv.Value("CAENMessage")
	$tsenv.Value("CAENMessage") = ""
}
if ($tsenv.Value("CAENTitle") -ne ""){
	$Title = [string]$tsenv.Value("CAENTitle")
	$tsenv.Value("CAENTitle") = ""
}
if ($tsenv.Value("CAENIcon") -ne ""){
	$Icon = [int]$tsenv.Value("CAENIcon")
	$tsenv.Value("CAENIcon") = ""
}
if ($tsenv.Value("CAENButton") -ne ""){
	$Button = [int]$tsenv.Value("CAENButton")
	$tsenv.Value("CAENButton") = ""
}

#display message box
(New-Object -ComObject Wscript.Shell).popup($Message,$Timeout,$Title,$Button + $Icon)