Login-AzureRmAccount

$resourceGroupName = "larsbefilexfer"
$storageAccountName = "azstimtest"
$containerName = 'timcontainer'
$permission = "rwla"


Function New-SasURI
{
param
(
    $resourceGroupName,
    $storageAccountName,
    $containerName,
    $permission
)

$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

#store a SAS token as an Azure Automnation variable instead
$key = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName



$context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key[0].Value

$container = Get-AzureStorageContainer -Name $containerName -Context $context



$startTime = get-date
$ExpirationTime = $startTime.AddHours('1')

$containerSas = New-AzureStorageContainerSASToken -Name $containerName -Permission $permission -Context $context -StartTime $startTime -ExpiryTime $ExpirationTime -FullUri

$containerSas
}



$sas1 = New-SasURI -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -containerName $containerName -permission $permission

$sas2 = New-SasURI -resourceGroupName $resourceGroupName -storageAccountName "azstimtest1" -containerName $containerName -permission $permission



$sourcesplit = $sas1.Split('.')
$sourceStorageAccount = (($sourcesplit[0]).trimStart('//')).TrimStart('https://')
$sourcecontainerandsas = (($sourcesplit[4].TrimStart("net"))).TrimStart('/')
$sourcecontainer = $sourcecontainerandsas.Substring(0, $sourcecontainerandsas.IndexOf('?'))
$sourceSasToken = '?' + $sourcecontainerandsas.Split('?')[1]




$destinationsplit = $sas2.Split('.')
$destinationStorageAccount = (($destinationsplit[0]).trimStart('//')).TrimStart('https://')
$destinationcontainerandsas = (($destinationsplit[4].TrimStart("net"))).TrimStart('/')
$destinationcontainer = $destinationcontainerandsas.Substring(0, $destinationcontainerandsas.IndexOf('?'))
$destinationSasToken = '?' + $destinationcontainerandsas.Split('?')[1]




$azcopypath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\'
$AzCopyLogDirectory = "c:\temp"
$setbandwidth = 8

Set-Location $azcopypath
.\AzCopy /Source:https://$sourceStorageAccount.blob.core.windows.net/$sourcecontainer /Dest:https://$destinationStorageAccount.blob.core.windows.net/$destinationcontainer /SourceSAS:$sourceSasToken /DestSAS:$destinationSasToken /S /v:$AzCopyLogDirectory\azcopy.log /Z:$AzCopyLogDirectory\journal /NC:$setbandwidth /Y /pattern:test.txt
