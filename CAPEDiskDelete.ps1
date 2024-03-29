﻿function New-SCSIControllerVM($vmToUpdate, $busnumber) {
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

$credentials = Get-Credential
Connect-VIServer 172.18.40.30 -Credential $credentials
$NodosPrimarios = "BOGPVBDWP009", "BOGPVBDWP011", "BOGPVPPWP014"
$NodosSecundarios = "BOGPVBDWP010", "BOGPVBDWP012", "BOGPVPPWP015"
$PowerCliContext = Get-PowerCLIContext
$nodos = $NodosPrimarios + $NodosSecundarios
$BusNumbers = @()
for ($i=0; $i -lt $nodos.Length; $i++) {
  
  $BusNumbers += (Get-ScsiController -VM $nodos[$i]).Count - 1
}

  $NodosSecundarios | ForEach-Object -Parallel  {
    #Use-PowerCLIContext -PowerCLIContext $using:PowerCliContext -SkipImportModuleChecks 
    Get-HardDisk -VM $_ -DiskType RawPhysical  | Remove-HardDisk -Confirm:$false
   Get-hardDisk -VM $_ | Where-Object {($_.CapacityGB -eq '0')} | Remove-HardDisk -Confirm:$false
  }


$NodosPrimarios | ForEach-Object -parallel {
  Use-PowerCLIContext -PowerCLIContext $using:PowerCliContext -SkipImportModuleChecks
  Get-HardDisk -VM $_ -DiskType RawPhysical   | Remove-HardDisk -DeletePermanently:$true -Confirm:$false
  Get-hardDisk -VM $_ | Where-Object {($_.CapacityGB -eq '0')}  | Remove-HardDisk -Confirm:$false  
}


for ($i=0; $i -lt $BusNumbers.Length; $i++) {
  for($b=1; $b -le $BusNumbers[$i]; $b++){
    New-SCSIControllerVM $nodos[$i] $b
  }
  
}

Disconnect-VIServer -Confirm:$false
