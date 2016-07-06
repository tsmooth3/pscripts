param($computer,[switch]$homeSVRs,[switch]$delprof,[switch]$lowonly)

if($homeSVRs){
	$svr = get-xaapplicationreport "Home" | select -expand servernames | sort
	}
elseif($computer){$svr = $computer}
else{$svr = "."}

$logicalDisk = gwmi win32_LogicalDisk -computer $svr -cred $(get-credential)| ?{$_.drivetype -eq 3} | select @{Name="Server";Expression={$_.__SERVER}},@{Name="Drive";Expression={$_.DeviceID}},@{Name="SizeGB";Expression={"{0} GB" -f [math]::round($_.Size/1024/1024/1024,3)}},@{Name="UsedGB";Expression={"{0} GB" -f [math]::round(($_.Size-$_.FreeSpace)/1024/1024/1024,3)}},@{Name="FreeGB";Expression={"{0} GB" -f [math]::round($_.FreeSpace/1024/1024/1024,3)}},@{Name="PercentFree";Expression={"{0}%" -f [math]::round(100*$_.FreeSpace/$_.Size,1)}}

$logicalDisk | %{
		if($homeSVRs){
			if($_.Drive -eq "D:" -and $_.FreeSpace -le 2.5){
				$_
				if($delprof){invoke-command -computer $_.Server -script {delprof /q /i /d:3} -asjob}
			}
		}
		else{$_} 
}