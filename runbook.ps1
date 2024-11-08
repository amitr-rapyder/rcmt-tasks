workflow start-vm {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName = "CoE",
        [string]$VMName = "amit-demo",
        [string]$scriptPath = "/home/amitdemo/vmtask.sh"
    )

    inlineScript {
        $ResourceGroupName = $using:ResourceGroupName
        $VMName = $using:VMName
        $scriptPath = $using:scriptPath
        
        # Connect using Managed Identity
        Connect-AzAccount -Identity
    
        # Start the VM
        Write-Output "Starting VM: $VMName"
        Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    
        # Simple check for VM status
        do {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
            $powerState = ($vm.Statuses | Where-Object Code -like "PowerState/*").DisplayStatus
            Write-Output "Current VM state: $powerState"
            if ($powerState -ne "VM running") {
                Start-Sleep -Seconds 10
            }
        } while ($powerState -ne "VM running")
    
        # Execute commands
        Write-Output "Setting permissions..."
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId 'RunShellScript' -ScriptString "sudo chmod +x $scriptPath; cd /home/amitdemo; sudo chown amitdemo:amitdemo $scriptPath"
        
        Write-Output "Executing shell script on VM..."
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId 'RunShellScript' -ScriptString "cd /home/amitdemo; sudo -u amitdemo bash $scriptPath"
    }
}