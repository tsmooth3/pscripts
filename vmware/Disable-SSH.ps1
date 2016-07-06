Param($hostVM)

if( ($global:DefaultVIServer -ne $null) -and ($global:DefaultVIServer.IsConnected) ){
	if ($hostVM) {
		Write-Host "Disabling SSH on $hostVM ... " -noNewLine
		$null = Get-VMHost "$hostVM*" | Get-VMHostService | ?{$_.key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false
		Write-Host "Done." -Fore Green
	}
	else{
		Write-Host "Disabling SSH on all discovered Hosts"
		Get-VMHost | Get-VMHostService | ?{$_.key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false
		Write-host "done." -fore green
	}
}
else{
	Write-Host " Connect to vCenter first i.e. Connect-VIServer vcenter.fqdn.com" -fore White
	return 0
}