<#
.SYNOPSIS
    This script uploads Azure Stack logs to the Microsoft Azure Stack Analytics log storage.

.DESCRIPTION
    Providing a wrapper over AzCopy, this script uploads Azure Stack logs to the Microsoft Azure Stack Analytics log storage.

.PARAMETER TargetDirectory
    Specifies the directory you want to upload from, or download to based on the selected Mode. All child content in the directory is uploaded.
.PARAMETER SasUri
    Provides the SAS URI of the storage account, container, and SAS token for upload/download.
.PARAMETER SetBandwidth
	1-32, Specifies the number of threads used by AZcopy.
.PARAMETER Mode
    Specifies Upload or Download functionality. Default is to Upload. Download will filter anything starting with "extracted*" and download the container content.
.PARAMETER NoGui
	Switch that stops the simple GUI from loading.

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1

#This starts a Upload session using the gui

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1 -TargetDirectory "c:\temp\transfer" -SasUri 'https://STORAGEACCOUNT.blob.core.windows.net/CONTAINER?EXAMPLE-SAS-TOKEN-123456789'

#This Uploads using a SasUri containing Storage Account, Container, and SAS Token information.

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1 -TargetDirectory "c:\temp\transfer" -SasUri 'https://STORAGEACCOUNT.blob.core.windows.net/CONTAINER?EXAMPLE-SAS-TOKEN-123456789' -nogui

#This Uploads to a specific Storage Account and Container using the provided SAS token without the GUI.

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1 -mode Download

#This starts a Download session using the gui

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1 -TargetDirectory "c:\temp\transfer" -SasUri 'https://STORAGEACCOUNT.blob.core.windows.net/CONTAINER?EXAMPLE-SAS-TOKEN-123456789' -mode Download

#Download using the provided SasUri. You will be offered a selection of blobs to download.

.EXAMPLE
.\Azure_Stack_Data_Handler.ps1 -TargetDirectory "c:\example" -StorageAccount "12345example1" -Container "12345example2" -SasToken "?EXAMPLE-SAS-TOKEN-12345657689"  -Mode Download -NoGui

#Download using the provided SasUri. You will be offered a selection of blobs to download.

.NOTES
AzCopy is required to be installed in the default location.
External internet access is required.
#>


param(
	[String]$TargetDirectory,
    [String]$SasUri,
    [ValidateRange(1,32)]
    [int]$SetBandwidth = "8",
    [ValidateSet('Upload','Download')]
    [string]$Mode = "Upload",
    [Switch]$NoGui
	)

    Write-Host -ForegroundColor Yellow 
    ""  | Write-Host -ForegroundColor Yellow 
    " Copyright © 2017 Microsoft Corporation.  All rights reserved. " | Write-Host
    ""  | Write-Host -ForegroundColor Yellow 
    ' THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT ' | Write-Host -ForegroundColor Yellow 
    " WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT " | Write-Host -ForegroundColor Yellow 
    " LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS " | Write-Host -ForegroundColor Yellow 
    " FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  " | Write-Host -ForegroundColor Yellow 
    " RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. " | Write-Host -ForegroundColor Yellow 
    "------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow 
    ""  | Write-Host -ForegroundColor Yellow 
    " PowerShell Source Code " | Write-Host -ForegroundColor Yellow 
    ""  | Write-Host -ForegroundColor Yellow 
    " NAME: " | Write-Host -ForegroundColor Yellow 
    "    Azure_Stack_Data_Handler.ps1" | Write-Host -ForegroundColor Yellow 
    "" | Write-Host -ForegroundColor Yellow 
    " VERSION: " | Write-Host -ForegroundColor Yellow 
    "    3.0" | Write-Host -ForegroundColor Yellow 
    ""  | Write-Host -ForegroundColor Yellow 
    "------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow 
    "" | Write-Host -ForegroundColor Yellow 
    " This script is only provided for use with a valid Support Request number and contact with a Microsoft Azure Stack Support engineer." | Write-Host -ForegroundColor Yellow
    " The script itself will not provide a resolution to your issue. Please contact the Microsoft Engineer who provided this script with any questions regarding your case."  | Write-Host -ForegroundColor Yellow 
    " It will upload the log bundle to our diagnostics system for review. Data is tracked with the SR number."  | Write-Host -ForegroundColor Yellow
    " Your data privacy is important to us. Please see here for more info: https://www.microsoft.com/en-us/TrustCenter/Privacy/default.aspx"  | Write-Host -ForegroundColor Yellow 
    Write-Host ""
    


$azcopypath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\'
$origindir = (Get-Item -Path ".\" -Verbose).FullName
$AzCopyLogDirectory = [environment]::getfolderpath("mydocuments") + "\AzureStackLogs"


If ($script:SasUri)
{
    $script:blobUrl = $script:SasUri
    $script:sassplit = $script:bloburl.Split('.')
    $script:StorageAccount = ($script:sassplit[0].TrimStart('https:')).trimStart('//')
    $script:containerandsas = ($script:sassplit[4].TrimStart("net/"))
    $script:container = $script:containerandsas.Substring(0, $script:containerandsas.IndexOf('?'))
    $script:SasToken = '?' + $script:containerandsas.Split('?')[1]
    $script:TargetURL = $script:SasUri
}



Function AzCopyCheck
{
    param
    (
	[String]$AzCopyLogDirectory = $script:AzCopyLogDirectory
    )

    $inst = "MicrosoftAzureStorageTools.msi"
    $azcopypath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\'
    $azcopy = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AZcopy.exe'

    try
    {
        $Step = 2
        $StepText  = "Checking for AzCopy"
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

	    $azcheck = (Get-ItemProperty -Path "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe")
        Write-Host "AzCopy found. Configuring journal and log folder." -ForegroundColor Yellow
    }
    catch
    {
	    Write-Error "Unable to find AzCopy"
    }


    try
    {
        [void](mkdir $script:AzCopyLogDirectory -Force)
    }
    catch
    {
        Throw "Unable to create $script:AzCopyLogDirectory"
    }


    if ($azcheck -eq $null)
    {
    
        $Step = 3
        $StepText  = "Installing AzCopy"
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        do 
        {
            write-host ""
            write-host "AZCopy is required. It was not detected in the default location. Would you like to download and install it? (Y/N)" -f yellow
            $choice = read-host
            write-host ""
            $ok = @("Y","N") -contains $choice
            if ( -not $ok) { write-host "Invalid selection" }
        }
        until ( $ok )
        switch ( $choice ) 
        {
            "Y" 
            {
                write-host "You selected Yes. Downloading AZcopy from http://aka.ms/downloadazcopy and installing to C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"
                #download
                try
                {
                    Start-BitsTransfer -Source http://aka.ms/downloadazcopy -Destination $AzCopyLogDirectory\$inst |Wait-Process
                }
                catch
                {
                    Write-Error $_
                    Throw "Error downloading AzCopy."
                }
                #install
                try
                {
                    (Start-Process -wait "$AzCopyLogDirectory\$inst" /passive)
                }
                catch
                {
                    Write-Error $_
                    Throw "Error installing AzCopy."
                }
            }
            "N" 
            {
                write-host "You selected No. AzCopy is required." -ForegroundColor Yellow
                Exit                
	        }
        }
    }

}

Function AzCopyLogic
{
    param(
    [String]$TargetDirectory,
    [string]$TargetURL,
    [String]$StorageAccount,
    [String]$Container,
    [String]$SasToken,
    [ValidateSet('Upload','Download')]
    [string]$Mode = "Upload",
    [ValidateRange(1,32)]
    [int]$setbandwidth = 8,
    [String]$AzCopyLogDirectory = $script:AzCopyLogDirectory
    )

    if ($Mode -eq "Upload")
    {
        $Step = 4
        $StepText  = "Calculating size upload"
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        $colItems = (Get-ChildItem $TargetDirectory  -recurse | Measure-Object -property length -sum)
        $size = ("{0:N2}" -f ($colItems.sum / 1MB) + " MB")
        Write-Host ""
        Write-Host "Upload times will vary across environments. The total size of the log bundle is "-ForegroundColor cyan -NoNewline
        Write-Host "$size" -ForegroundColor Yellow
        $count = $colItems.Count
        Write-Host "The number of files to upload is "-ForegroundColor Cyan -NoNewline
        Write-Host "$count" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Starting to upload with Azcopy. Please check " -ForegroundColor Cyan -NoNewline
        Write-Host "$AzCopyLogDirectory\azcopy.log " -ForegroundColor Yellow -NoNewline
        Write-Host "if there are issues uploading" -ForegroundColor Cyan 
        Write-Host ""

        $Step = 5
        $StepText  = "Uploading" 
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        $azcopypath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\'
        Set-Location $azCopyPath
        .\azcopy /Source:`"$TargetDirectory`" /Dest:$TargetURL /S /v:$AzCopyLogDirectory\azcopy.log /Z:$AzCopyLogDirectory\journal /NC:$setbandwidth /Y
        Write-Host "Azcopy run is finished." -foregroundcolor Yellow
    }

    if ($Mode -eq "Download")
    {
        $Step = 4
        $StepText = "Calculating size of the blobs to download"
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        $st = get-module Azure.Storage
        if ($st -eq $null)
        {
            Write-Output "Attempting to run import-module azure.storage"
            try
            {
                import-module azure.storage
            }
            catch
            {
                Write-Error $_
                Throw "Azure.Storage powershell module not found. Unable to connect to the storage account."
            }
        }

        try
        {
            $context = New-AzureStorageContext -StorageAccountName $StorageAccount -SasToken $SasToken
        }
        catch
        {
            Write-Host "Unable to check the download size" -ForegroundColor Red
            Throw "Unable to set storage context for $StorageAccount"
        }


        Set-Location $azCopyPath
        Write-Host ""
        Write-Host "Starting to download files with Azcopy. Please check " -ForegroundColor Cyan -NoNewline                 
        Write-Host "$AzCopyLogDirectory\azcopy.log " -ForegroundColor Yellow -NoNewline
        Write-Host "if there are issues downloading." -ForegroundColor Cyan 
        Write-Host ""

        #get blobs
        
        #set context from the SAS   
        try
        {
            $context = New-AzureStorageContext -StorageAccountName $StorageAccount -SasToken $SasToken
        }
        catch
        {
            Write-Host "Unable to check the download size" -ForegroundColor Red
            Throw "Unable to set storage context for $StorageAccount"
        }

        #get blobs and convert to human readable
        $listOfBLobs = Get-AzureStorageBlob -Container $Container -Context $context |where {$_.Name -notlike "extracted*"}



            #build gui
        [void] [System.Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' )

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
    

            # Info form
        $blobForm = New-Object System.Windows.Forms.Form 
        $blobForm.Text = "Azure Stack Data Handler Blob Selection"
        $blobForm.Size = New-Object System.Drawing.Size(430,200)
        $blobForm.StartPosition = "CenterScreen"
        $blobForm.controlbox = $false
        $blobForm.KeyPreview = $True
        $blobForm.FormBorderStyle = 'FixedDialog'
        $blobForm.Topmost = $True


    
        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Point(100,120)
        $OKButton.Size = New-Object System.Drawing.Size(75,23)
        $OKButton.Text = 'OK'
        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $blobForm.AcceptButton = $OKButton
        $blobForm.Controls.Add($OKButton)

        $CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Location = New-Object System.Drawing.Point(200,120)
        $CancelButton.Size = New-Object System.Drawing.Size(75,23)
        $CancelButton.Text = 'Cancel'
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $blobForm.CancelButton = $CancelButton
        $blobForm.Controls.Add($CancelButton)

        $bloblabel = New-Object System.Windows.Forms.Label
        $bloblabel.Location = New-Object System.Drawing.Point(10,20)
        $bloblabel.Size = New-Object System.Drawing.Size(280,20)
        $bloblabel.Text = 'Please select from the list of Blobs below:'
        $blobForm.Controls.Add($bloblabel)


        $listBox = New-Object System.Windows.Forms.Listbox
        $listBox.Location = New-Object System.Drawing.Point(10,40)
        $listBox.Size = New-Object System.Drawing.Size(380,20)


        $listBox.SelectionMode = 'MultiExtended'
        $listBox.Height = 70



        foreach ($blob in $listOfBLobs)
        {
            [void]$listBox.Items.Add($blob.Name)
        }


        $blobForm.Controls.Add($listBox)
        $blobForm.Topmost = $true

        $result = $blobForm.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $selectedBlobs = $listBox.SelectedItems

            if ($listbox.SelectedItems.Count -eq 0)
            {
                Write-Error "No blobs selected"
                Write-host ""
                Throw "Please select a blob for download"
            }


            $colitems = @()
            $count = 0
            $sum = @()

            foreach ($choice in $selectedblobs)
            {
                $blobsize = $listOfBLobs|where {$_.Name -eq $choice}
                $colItems += ($blobsize | Measure-Object -property length -sum)
                $sum += $colItems.Sum
                $count++
            }

            $total = 0
            foreach ($item in $sum)
            {
                $total = $total + [int]$item
            }
            $size = ("{0:N2}" -f ($total / 1MB) + " MB")


            # output the blobs and their sizes and the total 
            Write-Host "" 
            Write-Host "List of blobs being downloaded:" -ForegroundColor Cyan
            foreach ($selection in $selectedBlobs)
            {
                Write-Host $selection -ForegroundColor Yellow
            }
            Write-Host "" 
            Write-Host "Download times will vary across environments. The total size is "-ForegroundColor cyan -NoNewline
            Write-Host "$size" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "The number of files to download is "-ForegroundColor Cyan -NoNewline
            Write-Host "$count" -ForegroundColor Yellow
            Write-Host ""
            Write-Host 
        }


        $Step = 5
        $StepText = "Downloading"
        $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
        $StatusBlock = [ScriptBlock]::Create($StatusText)
        Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

        $blobUrl = "https://$StorageAccount.blob.core.windows.net/$Container"
        foreach ($selection in $selectedBlobs)
        {
            .\azcopy.exe /Source:`"$blobUrl`" /SourceSAS:$SasToken /Dest:$TargetDirectory /S /v:$AzCopyLogDirectory\azcopy.log /Z:$AzCopyLogDirectory\journal /Pattern:$selection /NC:$setbandwidth /Y
            Write-Host "Downloaded $name" -ForegroundColor Yellow
        }

        Write-Host "Azcopy run is finished." -foregroundcolor Yellow
    }

    Set-Location $script:origindir

}


Function AzS-Upload
{
    param(
        [String]$TargetDirectory,
        [String]$StorageAccount,
        [String]$Container,
        [String]$SasToken,
        [ValidateSet('Upload','Download')]
        [string]$Mode,
        [ValidateRange(1,32)]
        [int]$SetBandwidth = "8",
        [String]$AzCopyLogDirectory,
        [String]$TargetURL
	    )

    $Activity = "Azure Stack Data Handler - Uploading"
    $Id = 1
    $TotalSteps = 5
    $Step = 1
    $StepText = "Preparing"
    $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
    $StatusBlock = [ScriptBlock]::Create($StatusText)
    Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

    AzCopyCheck -AzCopyLogDirectory $AzCopyLogDirectory

    AzCopyLogic -TargetDirectory $TargetDirectory -TargetURL $script:TargetURL -StorageAccount $StorageAccount -Container $Container -SasToken $SasToken -Mode Upload -setbandwidth $setbandwidth -AzCopyLogDirectory $script:AzCopyLogDirectory

    Set-Location $origindir
}

Function Azs-Download
{
    param(
        [String]$TargetDirectory,
        [String]$StorageAccount,
        [String]$Container,
        [String]$SasToken,
        [ValidateSet('Upload','Download')]
        [string]$Mode,
        [ValidateRange(1,32)]
        [int]$SetBandwidth = "8",
        [String]$AzCopyLogDirectory,
        [String]$TargetURL
	    )

    $Activity = "Azure Stack Data Hanlder - Download"
    $Id = 1
    $TotalSteps = 5
    $Step = 1
    $StepText = "Preparing"
    $StatusText = '"Step $($Step.ToString().PadLeft("$TotalSteps.Count.ToString()".Length)) of $TotalSteps | $StepText"'
    $StatusBlock = [ScriptBlock]::Create($StatusText)
    Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

    AzCopyCheck -AzCopyLogDirectory $AzCopyLogDirectory

    AzCopyLogic -TargetDirectory $TargetDirectory -TargetURL $script:TargetURL -StorageAccount $StorageAccount -Container $Container -SasToken $SasToken -Mode Download -setbandwidth $setbandwidth -AzCopyLogDirectory $script:AzCopyLogDirectory

    Set-Location $origindir

}

Function BuildGui
{
    param
    (
    [String]$TargetDirectory,
    [String]$StorageAccount,
    [String]$Container,
    [String]$SRnumber,
    [String]$SasToken,
    [ValidateSet('Upload','Download')]
    [string]$mode
	)

        #build gui
    [void] [System.Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' )

        # Info form
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Azure Stack log $mode"
    $objForm.Size = New-Object System.Drawing.Size(450,250)
    $objForm.StartPosition = "CenterScreen"
    $objForm.controlbox = $false
    $objForm.KeyPreview = $True
    $objForm.FormBorderStyle = 'FixedDialog'
    $objForm.Topmost = $True

            # label for log bundle
    $objlabel1 = New-Object System.Windows.Forms.CheckBox
    $objlabel1.Location = New-Object System.Drawing.Size(10,10) 
    $objlabel1.Size = New-Object System.Drawing.Size(400,20) 
    $objlabel1.Text = "Path to Target Directory:"
    $objlabel1_Checked = {

    if ($objlabel1.Checked -eq $true)
    {
        Function Select-FolderDialog
        {
            param([string]$Description="Select the folder for your Azure Stack log bundle",[string]$RootFolder="Desktop")

            [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null     
            $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
            $objForm.Rootfolder = $RootFolder
            $objForm.Description = $Description
            $Show = $objForm.ShowDialog()
            if ($Show -eq "OK")
            {
                Return $objForm.SelectedPath
            }
            else
            {
                Write-Warning "Folder selection operation cancelled by user."
                $objlabel1.Checked = $false
                $objlogBox.Text = $null
            }
        }
        $objlogBox.Text = Select-FolderDialog    
    }
    else
    {
        $objlogBox.Text = $null}
    }

    $objlabel1.add_CheckedChanged($objlabel1_Checked)
    $objForm.Controls.Add($objlabel1) 

    # log bundle box
    $objlogBox = New-Object System.Windows.Forms.TextBox 
    $objlogBox.Location = New-Object System.Drawing.Size(10,30) 
    $objlogBox.Size = New-Object System.Drawing.Size(410,20) 
    $objForm.Controls.Add($objlogBox) 
    $objForm.Topmost = $True
    $objForm.Add_Shown({$objForm.Activate()})    
    $objlogBox.Text = $TargetDirectory

    # label for SASuri
    $objlabel5 = New-Object System.Windows.Forms.Label
    $objlabel5.Location = New-Object System.Drawing.Size(10,60) 
    $objlabel5.Size = New-Object System.Drawing.Size(410,20) 
    $objlabel5.Text = "SAS Uri:"
    $objForm.Controls.Add($objlabel5)

    # SASuri box
    $objuriBox = New-Object System.Windows.Forms.TextBox 
    $objuriBox.Location = New-Object System.Drawing.Size(10,80)
    $objuriBox.Size = New-Object System.Drawing.Size(410,20) 
    $objForm.Controls.Add($objuriBox) 
    $objForm.Topmost = $True
    $objForm.Add_Shown({$objForm.Activate()})    
    $objuriBox.Text = $TargetURL


    # ok button
    $OKButton = New-Object System.Windows.Forms.Button]
    $OKButton.Location = New-Object System.Drawing.Size(125,170)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $objForm.Controls.Add($OKButton)
    $objform.AcceptButton = $OKButton

    # cancel button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(225,170) 
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $objform.CancelButton = $CancelButton
    $objForm.Controls.Add($CancelButton)

    #add buttons
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $result = $objform.ShowDialog()

    if ($result –eq [System.Windows.Forms.DialogResult]::OK)
    {

        If ($objuriBox.Text -ne $null)
        {
            $blobUrl = $objuriBox.Text
            $sassplit = $blobUrl.Split('.')
            $script:StorageAccount = ($sassplit[0].TrimStart('https:')).trimStart('//')
            $containerandsas = ($sassplit[4].TrimStart("net/"))
            $script:container = $containerandsas.Substring(0, $containerandsas.IndexOf('?'))
            $script:SasToken = '?' + $containerandsas.Split('?')[1]
            $script:TargetURL = $objuriBox.Text
            $script:TargetDirectory = (($objlogBox).Text)

            [void]$objForm.Close()
        }


    }
    else
    {
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
        {Write-Warning "Exiting, user canceled"
        Exit
        }
    }
}

Function PrintSubmission
{
    Write-Host ""
    write-host "TargetDirectory: " -NoNewline -ForegroundColor Cyan
    Write-Host "$script:TargetDirectory" -ForegroundColor Yellow
    write-host "StorageAccount: " -NoNewline -ForegroundColor Cyan 
    Write-Host "$script:StorageAccount" -ForegroundColor Yellow
    write-host "Container: " -NoNewline -ForegroundColor Cyan
    Write-Host "$script:Container" -ForegroundColor Yellow
    write-host "SasToken: " -NoNewline -ForegroundColor Cyan
    Write-Host "$script:SasToken" -ForegroundColor Yellow
    Write-Host ""
    write-host "AzCopyLogDirectory: " -NoNewline -ForegroundColor Cyan
    Write-Host "$script:AzCopyLogDirectory" -ForegroundColor Yellow
    Write-Host ""
}


if ($NoGui)
{
    PrintSubmission

    if ($StorageAccount -eq $null -or $Container -eq $null -or $SasToken -eq $null)
    {
        Throw "To run without the GUI, please set the variables for TargetDirectory, and SasUri"
    }

    if ($Mode -eq "Upload")
    {
        AzS-Upload -StorageAccount $StorageAccount -Container $Container -TargetDirectory $TargetDirectory -SasToken $SasToken -setbandwidth $setbandwidth -NoGui -Mode Upload -AzCopyLogDirectory $AzCopyLogDirectory
    }

    if ($Mode -eq "Download")
    {
        AzS-Download -StorageAccount $StorageAccount -Container $Container -TargetDirectory $TargetDirectory -SasToken $SasToken -setbandwidth $setbandwidth -NoGui -Mode Download -AzCopyLogDirectory $AzCopyLogDirectory
    }
}


if (!$NoGui)
{
    BuildGui -TargetDirectory $TargetDirectory -StorageAccount $StorageAccount -Container $Container  -SasToken $SasToken -mode $Mode 
    PrintSubmission

    if ($StorageAccount -eq $null -or $Container -eq $null -or $SasToken -eq $null)
    {
        Throw "Please set the variable for -SasURI"
    }

    if ($Mode -eq "Upload")
    {      
        AzS-Upload -StorageAccount $StorageAccount -Container $Container -TargetDirectory $TargetDirectory -SasToken $SasToken -setbandwidth $setbandwidth -Mode Upload
    }

    if ($Mode -eq "Download")
    {
        AzS-Download -StorageAccount $StorageAccount -Container $Container -TargetDirectory $TargetDirectory -SasToken $SasToken -setbandwidth $setbandwidth -Mode Download
    }   
}
