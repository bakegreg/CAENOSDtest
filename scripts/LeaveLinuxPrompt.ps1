if (test-path (join-path $env:TEMP -ChildPath "linuxexists.txt")){
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

	#Close the TS UI temporarily
	$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
	$TSProgressUI.CloseProgressDialog()

	#$SecondsToWait = 60 #amount of time before the box automatically closes
	$Title = "CAEN Install Option"
	$Button = 4 #a yes/no button option (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
	#$Icon = 64 #an Information icon
	$Message = "Refresh both Windows and Linux?`n`nYes = Windows and Linux are refreshed.`nNo = Only Windows is refreshed."
	#$DefaultToNo = 256

	#$choice = (New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon + $DefaultToNo)
	$Output = 0
	$tsenv.Value('LeaveLinux') = "true" #Setting the default option to refreshing only Windows
	$TSProgressUi.ShowMessageEx($Message, $Title, $Button, [ref]$Output)
	if ($Output -ne 6){ #6 equals a 'Yes'
		$tsenv.Value('LeaveLinux') = "true"
	}
}
	