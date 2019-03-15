Param
(
    [Parameter (Mandatory= $true)]
    [String] $UNCpathToCollectTo,
    [Parameter (Mandatory = $true)]
    [string] $ErcsVMip,
    [Parameter (Mandatory= $false)]
    [String] $roles = "*",
    [Parameter (Mandatory = $false)]
    [datetime] $StartTime,
    [Parameter (Mandatory = $false)]
    [datetime] $EndTime
)

#Define your automation variable names
$CloudAdminVariable = 'LNV4-CloudAdmin'
$ShareUserVariable = 'tim lab share creds'

#Your Cloud Admin credential
$CloudAdminCredential = Get-AutomationPSCredential -Name $CloudAdminVariable
$CloudAdminUser = $CloudAdminCredential.UserName
$CloudAdminPassword = $CloudAdminCredential.Password
$CloudAdminCred = New-Object System.Management.Automation.PSCredential($CloudAdminUser,$CloudAdminPassword)



#Your Share Credential
$ShareUserCredential = Get-AutomationPSCredential -Name $ShareUserVariable
$ShareUser = $ShareUserCredential.UserName
$ShareUserPassword = $ShareUserCredential.Password
$ShareUserCred = New-Object System.Management.Automation.PSCredential($ShareUser,$ShareUserPassword)


$splitIps = $ErcsVMip.Split(",")

$Folder = "$UNCpathToCollectTo"
try
{
    mkdir $folder -force
}
catch
{
    Write-Error $_
    Throw "Unable to make directory $Folder"
}

#Attempt to connect to ERCS VMs
try
{
    $s = New-PSSession -ComputerName $splitIps[0] -ConfigurationName PrivilegedEndpoint -Credential $CloudAdminCred
    $ercs = $splitIps[0]
    Write-Output "Connected to $ercs"
}
catch
{
    Write-Error $_
    
    try
    {
        $s = New-PSSession -ComputerName $splitIps[1] -ConfigurationName PrivilegedEndpoint -Credential $CloudAdminCred
        $ercs = $splitIps[1]
        Write-Output "Connected to $ercs"
    }
    catch
    {
        Write-Error $_
        try
        {
            $s = New-PSSession -ComputerName $splitIps[2] -ConfigurationName PrivilegedEndpoint -Credential $CloudAdminCred
            $ercs = $splitIps[2]
            Write-Output "Connected to $ercs"
        }
        catch
        {
            Write-Error $_
            Throw "Unable to connect to any of the ERCS VMs; $splitIps"
        }
    }
}

#Attempt log collection, defaults to last 4 hours unless StartTime and EndTime are provided
try
{
    if ($StartTime -and $EndTime)
    {
        
        icm $s {Get-AzureStackLog -OutputSharePath $using:Folder -OutputShareCredential $using:ShareUserCred -FilterbyRole $using:roles -FromDate $using:Starttime -ToDate $using:EndTime -verbose}
           
    }
    else
    {
        icm $s {Get-AzureStackLog -OutputSharePath $using:Folder -OutputShareCredential $using:ShareUserCred -FilterbyRole $using:roles -verbose}
    }
}
catch
{
    Write-Error $_
    Throw "Log collection had a problem"
}

if ($s)
{
    Remove-PSsession $s
}
