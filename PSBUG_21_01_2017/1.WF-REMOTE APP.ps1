[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")


#Creating Form
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "REMOTE ACCESS"
$objForm.Size = New-Object System.Drawing.Size(500,300) 
$objForm.StartPosition = "CenterScreen"
$objForm.Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

#Creating Label -Computer Name
$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "COMPUTER NAME"
$objForm.Controls.Add($objLabel) 

#Creating Textbox -To insert Computer Name
$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox) 


#Creating Connect Button
$ConnectButton = New-Object System.Windows.Forms.Button
$ConnectButton.Location = New-Object System.Drawing.Size(300,40)
$ConnectButton.Size = New-Object System.Drawing.Size(75,23)
$ConnectButton.Text = "CONNECT"
$ConnectButton.Add_Click({(ButtonConnect_Click)})
$objForm.Controls.Add($ConnectButton)


#Creating GET-SERVICE Button
$ServiceButton = New-Object System.Windows.Forms.Button
$ServiceButton.Location = New-Object System.Drawing.Size(10,80)
$ServiceButton.Size = New-Object System.Drawing.Size(75,23)
$ServiceButton.Text = "SERVICES"
$ServiceButton.Add_Click({(ButtonService_Click)})
$objForm.Controls.Add($ServiceButton)

#Creating GET-PROCESS Button
$ProcessButton = New-Object System.Windows.Forms.Button
$ProcessButton.Location = New-Object System.Drawing.Size(110,80)
$ProcessButton.Size = New-Object System.Drawing.Size(75,23)
$ProcessButton.Text = "PROCESS"
$ProcessButton.Add_Click({(ButtonProcess_Click)})
$objForm.Controls.Add($ProcessButton)

#Creating GET-EVENTVIEWER Button
$EventViewerButton = New-Object System.Windows.Forms.Button
$EventViewerButton.Location = New-Object System.Drawing.Size(200,80)
$EventViewerButton.Size = New-Object System.Drawing.Size(95,23)
$EventViewerButton.Text = "EVENTVIEWER"
$EventViewerButton.Add_Click({(ButtonEvent_Click)})
$objForm.Controls.Add($EventViewerButton)

#Creating GET-APPWIZCPL Button
$AppwizcplButton = New-Object System.Windows.Forms.Button
$AppwizcplButton.Location = New-Object System.Drawing.Size(320,80)
$AppwizcplButton.Size = New-Object System.Drawing.Size(95,23)
$AppwizcplButton.Text = "APPWIZCPL"
$AppwizcplButton.Add_Click({(ButtonAppwiz_Click)})
$objForm.Controls.Add($AppwizcplButton)

#Creating Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(400,230)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

Function ButtonConnect_Click()
{

    $MACHINE = $objTextBox.Text
    $OS = (Get-WmiObject Win32_OperatingSystem -ComputerName  $MACHINE).Name
    $architecture = (Get-WmiObject Win32_OperatingSystem -ComputerName  $MACHINE).OSArchitecture

     

    #Creating Label
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,120)
    $objLabel.Size = New-Object System.Drawing.Size(300,15) 
    $objLabel.Text = 'Operating System  - ' + $OS 
    $objForm.Controls.Add($objLabel) 


    #Creating Label
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,140)
    $objLabel.Size = New-Object System.Drawing.Size(300,20) 
    $objLabel.Text = 'OS Architecture  - ' + $architecture 
    $objForm.Controls.Add($objLabel) 


    $p = @(
	    'DeviceID',
	    @{ Name = "Size(GB)  "; Expression = { [decimal]("{0:N0}" -f ($_.size/1gb)) } },
	    @{ Name = "Free Space(GB)  "; Expression = { [decimal]("{0:N0}" -f ($_.freespace/1gb)) } },
	    @{ Name = "Free (%)"; Expression = { "{0,6:P0}" -f (($_.freespace/1gb) / ($_.size/1gb)) } }
    )

    $disks = Get-WmiObject Win32_logicaldisk -ComputerName $MACHINE 

    #Creating Label
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,160) 
    $objLabel.Size = New-Object System.Drawing.Size(300,300)
    $objLabel.Text = $disks | Format-Table -Property $p -AutoSize | Out-String
    $objForm.Controls.Add($objLabel) 


}


Function ButtonService_Click()
{

     $MACHINE = $objTextBox.Text
     GET-SERVICE -computername $MACHINE  |Out-GridView

}


Function ButtonProcess_Click()
{

     $MACHINE = $objTextBox.Text
     GET-PROCESS -computername $MACHINE  |Out-GridView


}



Function ButtonEvent_Click()
{

     $MACHINE = $objTextBox.Text
     GET-Eventlog -Newest 5 -Logname Application -computername $MACHINE|Out-GridView


}

Function ButtonAppwiz_Click()
{

     $MACHINE = $objTextBox.Text
     Invoke-Command -computername $MACHINE  -ScriptBlock{ Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | select DisplayName, Publisher, InstallDate} |Out-GridView


}

