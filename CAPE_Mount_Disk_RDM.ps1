# Requiere Nodo#-#.csv o Allnode.csv
function Set-MultiwriterDeviceNode ($vmToUpdate, $HDNameUpdate, $DeviceNodeUpdate){		
	$VM = Get-VM $vmToUpdate | Select-Object Id
	$VM = Get-View -Id $vm.id
	$hdskToChange = Get-HardDisk -VM $vmToUpdate -Name $HDNameUpdate
	$datosbacking =$hdskToChange.ExtensionData.backing
	$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
	$spec.deviceChange[0].operation = 'edit'
	$spec.deviceChange[0].device = New-Object VMware.Vim.VirtualDisk
	$spec.deviceChange[0].device = $hdskToChange.ExtensionData
	$spec.DeviceChange[0].device.backing = New-Object VMware.Vim.VirtualDiskFlatVer2BackingInfo
	$spec.DeviceChange[0].device.backing = $datosbacking
	$spec.DeviceChange[0].device.Backing.Sharing = "sharingMultiWriter"
	$spec.deviceChange[0].device.unitNumber = $DeviceNodeUpdate
	$VM.ReconfigVM_Task($spec)
	
	}
	
	Connect-VIServer 172.18.40.30
	Get-Cluster -Name ITX-MED-CLUSTER1 | Get-VMHost | Get-VMHostStorage -RescanAllHba
	$VMs= Import-CSV .\Nodo11-12.csv
	$VMs|ForEach-Object {
	$HDname = $_.HDName
	New-HardDisk -VM $_.Name -DiskType RawPhysical -DeviceName $_.LUN -Controller $_.SCSIController
	$Disk = Get-HardDisk -VM $_.Name -DiskType RawPhysical | Select-Object name,filename |Where-Object {($_.Name -eq $HDname)}
	New-HardDisk -VM $_.Nodo2 -DiskPath $Disk.Filename  -Persistence IndependentPersistent -Controller $_.SCSIController
	Set-MultiwriterDeviceNode $_.name $_.HDName $_.devicenode
	Set-MultiwriterDeviceNode $_.Nodo2 $_.HDNameNodo2 $_.devicenode
	}
	
	Disconnect-VIServer -Confirm:$false


 
