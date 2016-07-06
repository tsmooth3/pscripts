# capture modem uptime and signal data
# tested against the following modem
### Model Name: SB6141
### Vendor Name: Motorola
### Firmware Name: SB_KOMODO-1.0.6.16-SCM00-NOSH
### Boot Version: PSPU-Boot(25CLK) 1.0.12.18m3
### Hardware Version: 7.0
### Firmware Build Time: Feb 16 2016 11:28:04
# tested with PS Version
### $PSVersionTable.PSVersion
### Major  Minor  Build  Revision
### -----  -----  -----  --------
### 4      0      -1     -1
# REQUIRES
# IE first-launch configuration
# http://wahlnetwork.com/2015/11/17/solving-the-first-launch-configuration-error-with-powershells-invoke-webrequest-cmdlet/

#User Defined variables
$baseHost = "192.168.100.1" #modem LAN IP
$portNumber = "80"
if($portNumber -eq "80"){ $portNumber = "" } 
else { $portNumber = ":$portNumber" }
$signalURL = "http://$baseHost$portNumber/cmSignalData.htm"
$upTimeURL = "http://$baseHost$portNumber/indexData.htm"

$outFilePath = "C:\pscripts\output"
$outFileName = "$(get-date -format "yyyyMMdd_HHmmss")_output.txt"

#ping test to make sure modem is responding
$pingTimeout = 2000 #ms
$strIP = $baseHost
$boolTestPing = $false
#$isItUp = $false
$return = @()

$timestamp = get-date -format o
#if it's not pinging, don't bother
Write-Host "$timestamp - Test Ping to $strIP for $pingTimeout ms ... " -NoNewLine
try
{
	$pingTest = (New-Object System.Net.NetworkInformation.Ping).Send($strIP,$pingTimeout).Status 
	if($pingTest -ne 'Success') { $boolTestPing = $false; Write-host "failed" -ForegroundColor Red }
	else { $boolTestPing = $true; Write-Host "OK" -ForegroundColor Green } 
}
Catch
{
	$boolTestPing = $false; write-host "failed - exception" -ForegroundColor Red 
}

if($boolTestPing) { 
	#$isitup = $true
	
	$signalData = Invoke-WebRequest -Uri $signalURL
	$upTimeData = Invoke-WebRequest -Uri $upTimeURL
	#upTime in format "# days #h:#m:#s"
    $upTime = $($upTimeData.ParsedHTML.getElementsByTagName("TD") | ?{$_.innerText -match "days"}).innerText

    #parse HTML tables and extract data into PSObject
	$oTables = $signalData.parsedHtml.getElementsByTagName("TABLE")
	$plTables = $oTables | ?{$_.innerHTML -match ">Power Level"}

	foreach ($plTable in $plTables){
		$dsTable = $plTable.ChildNodes | ?{$_.tagName -eq "tbody"}
		$dsTRs = $dsTable.childNodes | ?{$_.tagName -eq "tr"}
		$dsTableName = ($dsTRs[0].childNodes | ?{$_.tagName -eq "th"}).childNodes[0].innerText #downstream
		
		$dsRows = @()
		foreach ($oTR in $dsTRs) {
			$dsTDs = $oTR.ChildNodes | ?{$_.tagName -eq "td"}
			if([String]::IsNullOrEmpty($dsTDs)) { continue }
			$oRow = New-Object PSObject
			for ($i=0; $i -lt $dsTDs.Count; $i++) {
				if($dsTDs[$i].innerText -match "Power Level") { $dsTDs[$i].innerText = "Power Level" }
				$oRow | Add-Member -MemberType NoteProperty -Name "$dsTableName$i" -Value $dsTDs[$i].innerText
			}
			$dsRows += $oRow
		}
		$return += $dsRows
	}
	
    $return += $upTime
}
else { 
	
	Write-Host "$timestamp - Ping failed - no attemp to connect to $signalURL"
}	
return $return | Tee-Object -FilePath "$outFilepath\$outFileName"