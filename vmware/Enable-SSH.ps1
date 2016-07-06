Param($esxiHost)

if( ($global:DefaultVIServer -ne $null) -and ($global:DefaultVIServer.IsConnected) ){
	if ($esxiHost) {
		Write-Host "Enabling SSH on $esxiHost ... " -noNewLine
		$null = Get-VMHost "$esxiHost*" | Get-VMHostService | ?{$_.key -eq "TSM-SSH"} | Start-VMHostService
		Write-Host "Done." -Fore Green
	}
	else{
		Write-Host "Enabling SSH on all discovered Hosts"
		Get-VMHost | Get-VMHostService | ?{$_.key -eq "TSM-SSH"} | Start-VMHostService
		Write-host "done." -fore green
	}
}
else{
	Write-Host " Connect to vCenter first i.e. Connect-VIServer vcenter.fqdn.com" -fore White
	return 0
}