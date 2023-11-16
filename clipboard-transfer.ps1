### Sample showing a PowerShell GUI with drag-and-drop ###

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$selectedPath = ""
$tempFilePath = "~\"
$tempTxtFile = $tempFilePath + "temp.txt"
$tempOutZipPath = ""
$decodeLabelText = "Clipboard MD5:  "

### Create form ###

$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = '470,550'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximumSize = $form.Size
$form.Topmost = $False

### Define controls ###

$encodeButton = New-Object System.Windows.Forms.Button
$encodeButton.Location = '5,5'
$encodeButton.Size = '75,50'
$encodeButton.Width = 120
$encodeButton.Text = "Encode"

$decodeButton = New-Object System.Windows.Forms.Button
$decodeButton.Location = '5,400'
$decodeButton.Size = '75,50'
$decodeButton.Width = 120
$decodeButton.Text = "Decode"

$getClipboard = New-Object System.Windows.Forms.Button
$getClipboard.Location = '5,280'
$getClipboard.Size = '75,30'
$getClipboard.Width = 120
$getClipboard.Text = "Get Clipboard"

$clearClipboard = New-Object System.Windows.Forms.Button
$clearClipboard.Location = '140,280'
$clearClipboard.Size = '75,30'
$clearClipboard.Width = 120
$clearClipboard.Text = "Clear Clipboard"

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = '5,375'
$outputTextBox.Size = '350,23'

$browserButton = New-Object System.Windows.Forms.Button
$browserButton.Location = New-Object System.Drawing.Point(360, 375)
$browserButton.Size = New-Object System.Drawing.Size(70, 20)
$browserButton.Text = 'Browse...'

$clearListCheckbox = New-Object Windows.Forms.Checkbox
$clearListCheckbox.Location = '140,9'
$clearListCheckbox.AutoSize = $True
$clearListCheckbox.Text = "Clear Temp Encode Files afterwards"
$clearListCheckbox.Checked = $True

$clearTempDecodeFileCheckbox = New-Object Windows.Forms.Checkbox
$clearTempDecodeFileCheckbox.Location = '140,404'
$clearTempDecodeFileCheckbox.AutoSize = $True
$clearTempDecodeFileCheckbox.Text = "Clear Temp Decode Files afterwards"
$clearTempDecodeFileCheckbox.Checked = $True

$overrideDecodeFileCheckbox = New-Object Windows.Forms.Checkbox
$overrideDecodeFileCheckbox.Location = '140,432'
$overrideDecodeFileCheckbox.AutoSize = $True
$overrideDecodeFileCheckbox.Text = "Override Exist Files"
$clearTempDecodeFileCheckbox.Checked = $True

$label = New-Object Windows.Forms.Label
$label.Location = '137,39'
$label.AutoSize = $True
$label.Text = "Drop files or folders here:"

$clearListButton = New-Object System.Windows.Forms.Button
$clearListButton.Location = '330,30'
$clearListButton.Size = '5,25'
$clearListButton.Width = 120
$clearListButton.Text = "Clear List"

$decodeLabel = New-Object Windows.Forms.Label
$decodeLabel.Location = '10,320'
$decodeLabel.Size = '400,25'
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
$form.Controls.Add($clearListCheckbox)
$form.Controls.Add($label)
$form.Controls.Add($decodeLabel)
$form.Controls.Add($listBox)
$form.Controls.Add($getClipboard)
$form.Controls.Add($clearClipboard)
$form.Controls.Add($statusBar)
$form.Controls.Add($clearListButton)
$form.Controls.Add($clearTempDecodeFileCheckbox)
$form.Controls.Add($overrideDecodeFileCheckbox)
$form.ResumeLayout()

### Encode function ###
Function Encode-File($InputFile){
    try {
        # Read the binary file
        $binaryData = [System.IO.File]::ReadAllBytes($(Resolve-Path $InputFile))

        # Convert the binary data to Base64 string
        $base64String = [System.Convert]::ToBase64String($binaryData)

        # Write the encoded data to a text file
        Set-Content -Path $tempTxtFile -Value $base64String -Encoding ASCII
        
        $content = Get-Content -Raw $tempTxtFile

        Set-Clipboard -Value $content

        GetClipboard

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

        # Convert the Base64 string to binary data
        $binaryData = [System.Convert]::FromBase64String($base64String)

        # Create the normalized output file path
        $tempOutZipPath = $outputTextBox.Text + "\tempOut.zip"
        # Write the decoded binary data to a file
        [System.IO.File]::WriteAllBytes($tempOutZipPath, $binaryData)

        $statusBar.Text = "Base64 file decoded successfully."

        if($overrideDecodeFileCheckbox.Checked){
            Expand-Archive -Path $tempOutZipPath -DestinationPath $outputTextBox.Text -Force
        }else{
            Expand-Archive -Path $tempOutZipPath -DestinationPath $outputTextBox.Text -Confirm
        }
    }
    catch [Exception] {
        ##Write-Host "An error occurred while decoding the file: $_"
    }
}


Function GetClipboard() {
    # Get clipboard content
    # Read the Base64-encoded file
    $clipboard = Get-Clipboard -Format Text -Raw

    # Check if clipboard data is not empty
    if ($clipboard) {
        $clipboard = $clipboard -replace "`r`n","`n"
        $stream = [IO.MemoryStream]::new([byte[]][char[]]$clipboard)
        $hash = Get-FileHash -InputStream $stream -Algorithm MD5
        $size = [System.Text.Encoding]::ASCII.GetByteCount($clipboard)
       
        $decodeLabel.Text = $decodeLabelText + $hash.Hash + "`nSize: " + $size * 0.001 + " Kb"

    }
}

### Write event handlers ###

$encode_Click = {
    if($listBox.Items.Count.Equals(0)){
        $statusBar.Text = "No File in List, Drop File into it!"
    }else{
        $tempZipFile = $tempFilePath + "temp.zip"
        Compress-Archive -Path $listBox.Items -DestinationPath $tempZipFile -Force -Verbose
    
        Encode-File($tempZipFile)
 
        if($clearListCheckbox.Checked){
            Remove-Item -Path $tempTxtFile
            Remove-Item -Path $tempZipFile
        }
    }
}

$decode_Click = {
    $clipboard = Get-Clipboard

    if($outputTextBox.TextLength.Equals(0)){
        $statusBar.Text = "No Output Location Set"
    }else{
        Decode-File

        if($clearTempDecodeFileCheckbox.Checked){
            $tempOutZipPath = $outputTextBox.Text + "\tempOut.zip"
            Remove-Item $tempOutZipPath
        }
    }
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
            $totalSize += (Get-Item $filename).Length
        }

        $totalSize = 0
        foreach ($item in $listBox.Items) {
            $itemPath = $item.ToString()
            if (Test-Path -Path $itemPath -PathType Container) {
                $folderSize = (Get-ChildItem -Path $itemPath -Recurse | Measure-Object -Property Length -Sum).Sum
                $totalSize += $folderSize
            } else {
                $fileSize = (Get-Item -Path $itemPath).Length
                $totalSize += $fileSize
            }
        }
	}
    $statusBar.Text = ("List contains $($listBox.Items.Count) items, total:" + ($totalSize * 0.001) + "Kb")
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
    $statusBar.Text = ""
    [System.Windows.Forms.Clipboard]::Clear()
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

$getClipboard_Click = {
    GetClipboard
}

$clearClipboard_Click = {
    Set-Clipboard -Value $null
    $decodeLabel.Text = $decodeLabelText + "0" + "`nSize: 0 Kb"
}

### Wire up events ###

$encodeButton.Add_Click($encode_Click)
$decodeButton.Add_Click($decode_Click)
$browserButton.Add_Click($browser_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$listBox.Add_KeyDown($listBox_SelectDel)
$clearListButton.Add_Click($clearList_Click)
$getClipboard.Add_Click($getClipboard_Click)
$clearClipboard.Add_Click($clearClipboard_Click)
$form.Add_FormClosed($form_FormClosed)


#### Show form ###

[void] $form.ShowDialog()

