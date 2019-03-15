Param
(
    [Parameter (Mandatory= $false)]
    [String] $ResourceGroupName,

    [Parameter (Mandatory= $false)]
    [String] $StorageAccountName,

    [Parameter (Mandatory = $false)]
    [string] $ContainerName

)



$connectionName = "RunAsAccount"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
    Write-Output "Logging into Azure with $connectionName"
    Connect-AzureAD `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -TenantId $servicePrincipalConnection.TenantId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

}
catch {
   if (!$servicePrincipalConnection)
   {
      $ErrorMessage = "Connection $connectionName not found."
      throw $ErrorMessage
  } else{
      Write-Error -Message $_.Exception
      throw $_.Exception
  }
}



$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

#store a SAS token as an Azure Automnation variable instead
#$key = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
#Get encrypted key from Azure Automation
$Key = Get-AutomationVariable -Name "myStorageKey"


#Get the encrypted blob url
$context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$container = Get-AzureStorageContainer -Name $containerName -Context $context

$startTime = get-date
$ExpirationTime = $startTime.AddHours('1')

$containerSas = New-AzureStorageContainerSASToken -Name $containerName -Permission $permission -Context $context -StartTime $startTime -ExpiryTime $ExpirationTime -FullUri



