Param($computer,[switch]$xahome,[switch]$calabrio,[switch]$log,[switch]$lhc)

if($computer -eq $null){$computer = "."}
if($xahome){$computer = get-xaapplicationreport home | select -expand servernames | sort}


foreach($comp in $computer){
	if($log)
	{
		if(test-path \\$comp\c$\reboot.log){more \\$comp\c$\reboot.log}
		elseif(test-path \\$comp\m$\reboot.log){more \\$comp\m$\reboot.log}
		else{write-host "This script hasn't been executed on $comp yet."}
	}
	$psobj = new-object PSObject
	$wmiOsInformation = Get-WmiObject -computer $comp -class Win32_OperatingSystem 
	$startup = $wmiOsInformation.ConvertToDateTime($wmiOsInformation.LastBootUpTime)
	$psobj | add-member NoteProperty Computer $comp
	$psobj | add-member NoteProperty StartUpTime $startup
	if($lhc)
	{
		if(test-path \\$comp\c$\reboot.log){
			Get-Content \\$comp\c$\reboot.log | %{
				if($_.Contains(" LHC ")){$psobj | add-member NoteProperty LHCStatus $_}
			}
		}
		elseif(test-path \\$comp\m$\reboot.log){
			Get-Content \\$comp\m$\reboot.log | %{
				if($_.Contains(" LHC ")){$psobj | add-member NoteProperty LHCStatus $_}
			}
		}
		else{$psobj | add-member NoteProperty LHCStatus "no record"}
	}
	$psobj
}	