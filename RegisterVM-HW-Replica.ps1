# Se requiere del archivo Mount.csv

function Mount-DataStore($IdLun, $StorageID) {

    $resolutionSpec = New-Object VMware.Vim.HostUnresolvedVmfsResignatureSpec
    $resolutionSpec.ExtentDevicePath = New-Object String[] (1)
    $resolutionSpec.ExtentDevicePath[0] = $IdLun
    $_this = Get-View -Id $StorageID
    $_this.ResignatureUnresolvedVmfsVolume_Task($resolutionSpec)
}

$credentials = Get-Credential
Connect-VIServer 172.18.40.30 -Credential $credentials
$Luns =  "/vmfs/devices/disks/naa.6005076309ffd4bd0000000000002e18:1" , "/vmfs/devices/disks/naa.6005076309ffd4bd0000000000003000:1", "/vmfs/devices/disks/naa.6005076309ffd4bd0000000000002e15:1", "/vmfs/devices/disks/naa.6005076309ffd4bd0000000000002308:1"
$HostStorageID = 'HostDatastoreSystem-datastoreSystem-1174155' , 'HostDatastoreSystem-datastoreSystem-16' , 'HostDatastoreSystem-datastoreSystem-1165894'
$VMs= Import-CSV .\Mount.csv
Get-Cluster -Name ITX-MED-CLUSTER1 | Get-VMHost | Get-VMHostStorage -RescanAllHba

$i = 0
$luns | ForEach-Object {
    Mount-Datastore $_ $HostStorageID[$i]
    $i= $i + 1
    if ($i -eq 3){
        $i = 0
    }
}

Start-Sleep -Seconds 90

get-Datastore -name *Datastore_16_DS8886_V81* | Set-Datastore -name Datastore_16_DS8886_V81 | Move-Datastore -Destination "FNA"
get-Datastore -name *Datastore_01_DS8886_K51* | Set-Datastore -name Datastore_01_DS8886_K51 | Move-Datastore -Destination "FNA" 
get-Datastore -name *Datastore_15_DS8886_V81* | Set-Datastore -name Datastore_15_DS8886_V81 | Move-Datastore -Destination "FNA" 
get-Datastore -name *Datastore_09_DS8886_V81* | Set-Datastore -name Datastore_09_DS8886_V81 | Move-Datastore -Destination "FNA"
$VMs | ForEach-Object {
   
    New-VM -name $_.Name -VMFilePath $_.Path -Location "Replica HW" -RunAsync -ResourcePool "ITX-MED-CLUSTER1" -Confirm:$false
    Start-Sleep -Seconds 2
    Get-CDDrive -VM $_.Name | Remove-CDDrive -Confirm:$false
    $NetAdapters = Get-NetworkAdapter -VM $_.Name

    ForEach ($Net in $NetAdapters){

        switch ($Net.NetworkName) {
           "FNA_Prd_vlan131" {Set-NetworkAdapter -NetworkAdapter $Net -NetworkName "tenant.TenantFNA.vlan2606" -StartConnected:$true -Confirm:$false ; Break}
           "FNA_Backup_vlan20" {Set-NetworkAdapter -NetworkAdapter $Net -NetworkName "FNA_BD_SQL" -StartConnected:$true -Confirm:$false ; Break}
           "FNA_Prd_vlan151" {Set-NetworkAdapter -NetworkAdapter $Net -NetworkName "tenant.TenantFNA.vlan2607" -StartConnected:$true -Confirm:$false ; Break}
           "FNA_Admon_vlan15" {Set-NetworkAdapter -NetworkAdapter $Net -NetworkName "tenant.TenantFNA.vlan2604" -StartConnected:$true -Confirm:$false ; Break}
        Default{
            Set-NetworkAdapter -NetworkAdapter $Net  -StartConnected:$false -Confirm:$false

        }

        }

    }

 }

Disconnect-VIServer 172.18.40.30 -Confirm:$false




