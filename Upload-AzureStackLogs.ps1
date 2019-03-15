param
(
    [Parameter (Mandatory= $true)]
    [String]$SourceDirectory,
    [Parameter (Mandatory= $true)]
    [String]$TargetBlobURL,
    [Parameter (Mandatory= $false)]
    [ValidateRange(1,32)]
    [int]$SetBandwidth = "24",
    [Parameter (Mandatory= $true)]
    [String]$AzCopyLogDirectory
)


    
try
{
	$azcheck = (Get-ItemProperty -Path "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe")
}
catch
{
	Throw "Azcopy not found on Hybrid Runbook Machine the runbook was executed on"
}


$origindir = (Get-Item -Path ".\" -Verbose).FullName

try
{
    mkdir $AzCopyLogDirectory -Force|out-null
}
catch
{
    Write-Error $_
    Throw "Unable to make directory $AzCopyLogDirectory"
}

$azcopypath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\'



$colItems = (Get-ChildItem $SourceDirectory  -recurse | Measure-Object -property length -sum)
$size = ("{0:N2}" -f ($colItems.sum / 1MB) + " MB")
Write-Host ""
Write-Host "Upload times will vary across environments. The total size of the log bundle is "-ForegroundColor cyan -NoNewline
Write-Host "$size" -ForegroundColor Yellow
$count = $colItems.Count
Write-Host "The number of files to upload is "-ForegroundColor Cyan -NoNewline
Write-Host "$count" -ForegroundColor Yellow
Write-Host ""
Write-Host "Starting to upload with Azcopy. Please check " -ForegroundColor Cyan -NoNewline
Write-Host "$dir\azcopy.log " -ForegroundColor Yellow -NoNewline
Write-Host "on the Hybrid Runbook Worker if there are issues uploading" -ForegroundColor Cyan 
Write-Host ""

Set-Location $azCopyPath
try
{
    .\azcopy /Source:`"$SourceDirectory`" /Dest:$TargetBlobURL /S /v:$AzCopyLogDirectory\azcopy.log /Z:$AzCopyLogDirectory\journal /NC:$setbandwidth /Y
    Write-Host "AzCopy run is finished." -foregroundcolor Yellow
}
catch
{
    Write-Error $_
    Throw "Error uploading logs with AzCopy. Review the logs in $AzCopyLogDirectory"
}









