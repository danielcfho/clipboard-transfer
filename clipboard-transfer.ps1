### Sample showing a PowerShell GUI with drag-and-drop ###

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$selectedPath = ""
$tempFilePath = "~\"
$encodeLabelText = "Encode MD5:  "
$decodeLabelText = "Decode MD5:  "

### Create form ###

$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = '470,500'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True


### Define controls ###

$encodeButton = New-Object System.Windows.Forms.Button
$encodeButton.Location = '5,5'
$encodeButton.Size = '75,50'
$encodeButton.Width = 120
$encodeButton.Text = "Encode"

$decodeButton = New-Object System.Windows.Forms.Button
$decodeButton.Location = '5,350'
$decodeButton.Size = '75,50'
$decodeButton.Width = 120
$decodeButton.Text = "Decode"

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = '5,325'
$outputTextBox.Size = '350,23'

$browserButton = New-Object System.Windows.Forms.Button
$browserButton.Location = New-Object System.Drawing.Point(360, 325)
$browserButton.Size = New-Object System.Drawing.Size(70, 20)
$browserButton.Text = 'Browse...'

$checkbox = New-Object Windows.Forms.Checkbox
$checkbox.Location = '140,9'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear afterwards"

$label = New-Object Windows.Forms.Label
$label.Location = '137,39'
$label.AutoSize = $True
$label.Text = "Drop files or folders here:"

$clearListButton = New-Object System.Windows.Forms.Button
$clearListButton.Location = '330,30'
$clearListButton.Size = '5,25'
$clearListButton.Width = 120
$clearListButton.Text = "Clear List"

$encodeLabel = New-Object Windows.Forms.Label
$encodeLabel.Location = '5,270'
$encodeLabel.AutoSize = $True
$encodeLabel.Text = $encodeLabelText
$encodeLabel.AutoSize = $False

$decodeLabel = New-Object Windows.Forms.Label
$decodeLabel.Location = '5,410'
$decodeLabel.AutoSize = $True
$decodeLabel.Text = $decodeLabelText
$decodeLabel.AutoSize = $False

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 445
##$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True
$listBox.SelectionMode = 'MultiExtended'

$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"


### Add controls to form ###

$form.SuspendLayout()
$form.Controls.Add($encodeButton)
$form.Controls.Add($decodeButton)
$form.Controls.Add($outputTextBox)
$form.Controls.Add($browserButton)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($encodeLabel)
$form.Controls.Add($decodeLabel)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.Controls.Add($clearListButton)
$form.ResumeLayout()

### Encode function ###
Function Encode-File($InputFile){
    try {
        $hashOutput = Get-FileHash $InputFile -Algorithm MD5

        $encodeLabel.Text = $encodeLabelText + $hashOutput.Hash

        # Read the binary file
        $binaryData = [System.IO.File]::ReadAllBytes($(Resolve-Path $InputFile))

        # Convert the binary data to Base64 string
        $base64String = [System.Convert]::ToBase64String($binaryData)

        # Write the encoded data to a text file
        $tempTxtFile = $tempFilePath + "temp.txt"

        Set-Content -Path $tempTxtFile -Value $base64String -Encoding ASCII

        Get-Content -Raw $tempTxtFile | Set-Clipboard

        Start-Sleep -Seconds 1

        $statusBar.Text = "Binary txt copied to Clipboard, run Decode from other machine."

    }
    catch [Exception] {
        ##Write-Host "An error occurred while encoding the file: $_"
    }
}

Function Decode-File(){
    try {
        # Read the Base64-encoded file
        $base64String = Get-Clipboard

        Start-Sleep -Seconds 1

        # Convert the Base64 string to binary data
        $binaryData = [System.Convert]::FromBase64String($base64String)

        # Create the normalized output file path
        $tempOutZipPath = $outputTextBox.Text + "\tempOut.zip"

        #Write the decoded binary data to a file
        [System.IO.File]::WriteAllBytes($tempOutZipPath, $binaryData)

        $statusBar.Text = "Base64 file decoded successfully."

        $hashOutput = Get-FileHash $tempOutZipPath

        $decodeLabel.Text = $decodeLabelText + $hashOutput.Hash

        Expand-Archive -Path $tempOutZipPath -DestinationPath $outputTextBox.Text -Force

        Remove-Item $tempOutZipPath
    }
    catch [Exception] {
        ##Write-Host "An error occurred while decoding the file: $_"
    }
}

### Write event handlers ###

$encode_Click = {
    $tempZipFile = $tempFilePath + "temp.zip"
    Compress-Archive -Path $listBox.Items -DestinationPath $tempZipFile -Force -Verbose
    
    Encode-File($tempZipFile)

}

$decode_Click = {

    Decode-File
}

$browser_Click = {
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.SelectedPath = [Environment]::GetFolderPath('Desktop')
    if ($folderBrowserDialog.ShowDialog() -eq 'OK') {
        $selectedPath = $folderBrowserDialog.SelectedPath
        $outputTextBox.Text = $selectedPath
    }
}


$listBox_DragOver = [System.Windows.Forms.DragEventHandler]{
	if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
	{
	    $_.Effect = 'Copy'
	}
	else
	{
	    $_.Effect = 'None'
	}
}
	
$listBox_DragDrop = [System.Windows.Forms.DragEventHandler]{
	foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
    {
        if(!$listBox.Items.Contains($filename)){
		    $listBox.Items.Add($filename)
        }
	}
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$listBox_SelectDel = {
    if($_.KeyCode -eq 'Delete' -or $_.KeyCode -eq 'Back'){
        for ($i = $listBox.Items.Count - 1; $i -ge 0; $i--) {
            if ($listBox.SelectedIndices.Contains($i)) {
                $listBox.Items.RemoveAt($i)
            }
        }
    }
}

$clearList_Click ={
    $listBox.Items.Clear()
}

$form_FormClosed = {
	try
    {
        $listBox.remove_Click($encode_Click)
        $listBox.remove_Click($decode_Click)
		$listBox.remove_DragOver($listBox_DragOver)
		$listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_KeyDown($listBox_SelectDel)
		$form.remove_FormClosed($Form_Cleanup_FormClosed)
	}
	catch [Exception]
    { }
}

### Wire up events ###

$encodeButton.Add_Click($encode_Click)
$decodeButton.Add_Click($decode_Click)
$browserButton.Add_Click($browser_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$listBox.Add_KeyDown($listBox_SelectDel)
$clearListButton.Add_Click($clearList_Click)
$form.Add_FormClosed($form_FormClosed)


#### Show form ###

[void] $form.ShowDialog()