#ERASE ALL THIS AND PUT XAML BELOW between the @" "@
$inputXML = @"
<Window x:Class="Example.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Example"
        mc:Ignorable="d"
        Title="MainWindow" Height="350" Width="525">
    <Grid>
        <Button x:Name="button" Content="DISKINFO" HorizontalAlignment="Left" Margin="404,95,0,0" VerticalAlignment="Top" Width="88" Height="30" />
        <Label x:Name="label" Content="COMPUTER NAME" HorizontalAlignment="Left" Margin="24,95,0,0" VerticalAlignment="Top" Height="30" Width="123"/>
        <TextBox x:Name="textBox" HorizontalAlignment="Left" Height="28" Margin="162,97,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
        <Image x:Name="image" HorizontalAlignment="Left" Height="53" Margin="24,10,0,0" VerticalAlignment="Top" Width="321" Source="C:\Users\sunish\Desktop\Powershell Automation\SCRIPT\GUI\Example\Microsoft.png" />
        <ListView x:Name="listView" HorizontalAlignment="Left" Height="148" Margin="23,142,0,0" VerticalAlignment="Top" Width="467" RenderTransformOrigin="0.5,0.5">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Drive Letter" DisplayMemberBinding ="{Binding 'Drive Letter'}" Width="120"/>
                    <GridViewColumn Header="Drive Label" DisplayMemberBinding ="{Binding 'Drive Label'}" Width="120"/>
                    <GridViewColumn Header="Size(MB)" DisplayMemberBinding ="{Binding Size(MB)}" Width="120"/>
                    <GridViewColumn Header="FreeSpace%" DisplayMemberBinding ="{Binding FreeSpace%}" Width="120"/>
                </GridView>
            </ListView.View>
        </ListView>

    </Grid>
</Window>
"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

$reader=(New-Object System.Xml.XmlNodeReader $xaml)

try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}

catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}


 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}



#----------------------------PowerShell PART-------------------------------------

 
$WPFtextBox.Text = $env:COMPUTERNAME

#-----------------ButtonClick-----------------------------------------
 
$WPFbutton.Add_Click(

{
$WPFlistView.Items.Clear()
start-sleep -Milliseconds 840
Get-DiskInfo -computername $WPFtextBox.Text | % {$WPFlistView.AddChild($_)}
}

)
#--------------------------------------------------------------------
 
Function Get-DiskInfo 
{
param($computername =$env:COMPUTERNAME)
 
Get-WMIObject Win32_logicaldisk -ComputerName $computername | Select-Object @{Name='ComputerName';Ex={$computername}},`
                                                                    @{Name=‘Drive Letter‘;Expression={$_.DeviceID}},`
                                                                    @{Name=‘Drive Label’;Expression={$_.VolumeName}},`
                                                                    @{Name=‘Size(MB)’;Expression={[int]($_.Size / 1MB)}},`
                                                                    @{Name=‘FreeSpace%’;Expression={[math]::Round($_.FreeSpace / $_.Size,2)*100}}
                                                                 }
 



#------------------------------------------------------------------------

$Form.ShowDialog() | out-null