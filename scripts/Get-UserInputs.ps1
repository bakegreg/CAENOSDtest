function Get-UserInput {
    $title = "Enter Task Sequence Variables"

    $TextBox1 = "Ticket Number"
    $TextBox2 = "Primary User"
    $TextBox3 = "Computer Location"
    $TextBox4 = "Admins ( ; separated )"

    $Width = 600

    $LabelLeftOffset = 25
    $LabelTopOffset = 15
    $LabelWidth = 200

    $TextLeftOffset = $LabelLeftOffset+$LabelWidth+10
    $TextTopOffset = $LabelTopOffset
    $TextWidth = $Width - $TextLeftOffset - $LabelLeftOffset

    ###################Load Assembly for creating form & button######

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

    #####Define the form size & placement

    $form = New-Object "System.Windows.Forms.Form"
    $form.Width = $Width
    $form.Height = $LabelLeftOffset + 35*5 + 35
    $form.Text = $title
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    ##############Define text label1
    $textLabel1 = New-Object "System.Windows.Forms.Label"
    $textLabel1.Left = $LabelLeftOffset
    $textLabel1.Top = $LabelTopOffset
    $textLabel1.Width = $LabelWidth

    $textLabel1.Text = $TextBox1

    ##############Define text label2

    $textLabel2 = New-Object "System.Windows.Forms.Label";
    $textLabel2.Left = $LabelLeftOffset
    $textLabel2.Top = $LabelTopOffset + 35*1
    $textLabel2.Width = $LabelWidth

    $textLabel2.Text = $TextBox2

    ##############Define text label3

    $textLabel3 = New-Object "System.Windows.Forms.Label"
    $textLabel3.Left = $LabelLeftOffset
    $textLabel3.Top = $LabelTopOffset + 35*2
    $textLabel3.Width = $LabelWidth

    $textLabel3.Text = $TextBox3

    ##############Define text label4

    $textLabel4 = New-Object "System.Windows.Forms.Label"
    $textLabel4.Left = $LabelLeftOffset
    $textLabel4.Top = $LabelTopOffset + 35*3
    $textLabel4.Width = $LabelWidth

    $textLabel4.Text = $TextBox4

    ############Define text box1 for input
    $textBox1 = New-Object "System.Windows.Forms.TextBox"
    $textBox1.Left = $TextLeftOffset
    $textBox1.Top = $TextTopOffset
    $textBox1.width = $TextWidth

    ############Define text box2 for input

    $textBox2 = New-Object "System.Windows.Forms.TextBox"
    $textBox2.Left = $TextLeftOffset
    $textBox2.Top = $TextTopOffset + 35*1
    $textBox2.width = $TextWidth

    ############Define text box3 for input

    $textBox3 = New-Object "System.Windows.Forms.TextBox"
    $textBox3.Left = $TextLeftOffset
    $textBox3.Top = $TextTopOffset + 35*2
    $textBox3.width = $TextWidth

    ############Define text box4 for input

    $textBox4 = New-Object "System.Windows.Forms.TextBox"
    $textBox4.Left = $TextLeftOffset
    $textBox4.Top = $TextTopOffset + 35*3
    $textBox4.width = $TextWidth

    #############Define default values for the input boxes
    $defaultValue = ""
    $textBox1.Text = "1276344"
    $textBox2.Text = $defaultValue
    $textBox3.Text = '2252 GGB'
    $textBox4.Text = $defaultValue

    #############define OK button
    $button = New-Object "System.Windows.Forms.Button"
    $button.Left = 360
    $button.Top = $TextTopOffset + 35*4
    $button.Width = 100
    $button.Text = "OK"

    ############# This is when you have to close the form after getting values
    $eventHandler = [System.EventHandler]{
        $textBox1.Text
        $textBox2.Text
        $textBox3.Text
        $textBox4.Text
        $form.Close()
    };

    $button.Add_Click($eventHandler) 

    #############Add controls to all the above objects defined
    $form.Controls.Add($button)
    $form.Controls.Add($textLabel1)
    $form.Controls.Add($textLabel2)
    $form.Controls.Add($textLabel3)
    $form.Controls.Add($textLabel4)
    $form.Controls.Add($textBox1)
    $form.Controls.Add($textBox2)
    $form.Controls.Add($textBox3)
    $Form.Controls.Add($textBox4)
    $form.TopMost = $True
    $ret = $form.ShowDialog()

    #################return values

    return $textBox1.Text, $textBox2.Text, $textBox3.Text, $TextBox4.Text
}

#Connect to TS Environment
$TSEnv = New-Object -ComObject "Microsoft.SMS.TSEnvironment" 

$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

$UserInputs = Get-UserInput

$TSEnv.Value("METDxTicketNum") = $UserInputs[0]
$TSEnv.Value("MEComputerUser") = $UserInputs[1]
$TSEnv.Value("MEComputerLocation") = $UserInputs[2]
$TSEnv.Value("MEComputerAdmins") = $UserInputs[3]