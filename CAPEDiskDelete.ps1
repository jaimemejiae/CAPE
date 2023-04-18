function New-SCSIControllerVM($vmToUpdate, $busnumber) {
  $VM = Get-VM $vmToUpdate | Select-Object id
  $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
  $spec.DeviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
  $spec.DeviceChange[0].Device = New-Object VMware.Vim.ParaVirtualSCSIController
  $spec.DeviceChange[0].Device.SharedBus = 'noSharing'
  $spec.DeviceChange[0].Device.DeviceInfo = New-Object VMware.Vim.Description
  $spec.DeviceChange[0].Device.DeviceInfo.Summary = 'New SCSI controller'
  $spec.DeviceChange[0].Device.DeviceInfo.Label = 'New SCSI controller'
  $spec.DeviceChange[0].Device.BusNumber = $busnumber
  $spec.DeviceChange[0].Operation = 'add'
  $_this = Get-View -Id $vm.id
  $_this.ReconfigVM_Task($spec)
 
}
function Remove-Disk ($disksdelete, $VM) {

$disksdelete| ForEach-Object{

$ID = $_.Id.Substring($_.Id.Length-4)
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
$spec.DeviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
$spec.DeviceChange[0].Device = New-Object VMware.Vim.VirtualDisk
$spec.DeviceChange[0].Device.Key = $ID
$spec.DeviceChange[0].Operation = 'remove'
$spec.CpuFeatureMask = New-Object VMware.Vim.VirtualMachineCpuIdInfoSpec[] (0)
$_this = Get-View -ViewType VirtualMachine -Filter @{'Name'= $VM}
$_this.ReconfigVM_Task($spec)
}
}

$credentials = Get-Credential
Connect-VIServer 172.18.40.30 -Credential $credentials
$NodosPrimarios = "BOGPVBDWP009", "BOGPVBDWP011", "BOGPVBDWP0AD"
$NodosSecundarios = "BOGPVBDWP010", "BOGPVBDWP012", "BOGPVBDWP0AE"
$nodos = $NodosPrimarios + $NodosSecundarios
$BusNumbers = @()
for ($i=0; $i -lt $nodos.Length; $i++) {
  
  $BusNumbers += (Get-ScsiController -VM $nodos[$i]).Count - 1
}

  $NodosSecundarios | ForEach-Object  {
    Get-HardDisk -VM $_ -DiskType RawPhysical  | Remove-HardDisk -Confirm:$false
    $disks =Get-hardDisk -VM $_ | Where-Object {($_.CapacityGB -eq '0')} | Select-Object Id
    if($disks -ne $null){
      Remove-Disk $disks $_
    }

  }
$NodosPrimarios | ForEach-Object {

  Get-HardDisk -VM $_ -DiskType RawPhysical   | Remove-HardDisk -DeletePermanently:$true -Confirm:$false
  $disks =Get-hardDisk -VM $_ | Where-Object {($_.CapacityGB -eq '0')} | Select-Object Id
  if($disks -ne $null){
    Remove-Disk $disks $_
  }
}


for ($i=0; $i -lt $BusNumbers.Length; $i++) {
  for($b=1; $b -le $BusNumbers[$i]; $b++){
    New-SCSIControllerVM $nodos[$i] $b
  }
  
}

Disconnect-VIServer -Confirm:$false
