# Audit-DMZVMs.ps1
# Email if any VM is bridging DMZ and Internal networks

param (
	[string]	$vCenter = "<vcenter_FQDN>",
	[string]	$WhiteList = "<\\full\path\to\file\share\Audit-DMZVMs.csv>"
	)

$DMZDatastore = "-DMZ-"

if (Test-Path $WhiteList) {
	$WhiteListVMs = Import-CSV $WhiteList | Select -Expand Name
	}
else {
	Write-Host "Cannot find $WhiteList."
	Return
	}
	
$EmailServer = "<smtpserver_fqdn>"	
$EmailFrom = "DoNotReply@yourdomain.com"
$EmailTo = "yourvalidemail@yourdomain.com"
$EmailDebugTo = "yourvalidemail_admin@yourdomain.com"
$EmailSubject = "VMware DMZ Audit"
	
$VMwareSnapinName = "VMware.VimAutomation.Core"

function SendEmail([string]$Server, [string]$from, [string]$to, [string]$subject, [string]$body){
	$emailFrom = $from
	$emailTo = "$to"
	$smtpServer = $Server
	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	$smtp.Send($emailFrom, $emailTo, $subject, $body)
}

$TimeTaken = Measure-Command -Expression {
	
	if (!(Get-PSSnapin -Name $VMwareSnapinName -ErrorAction SilentlyContinue)) {
		# Add VMware automation snapin if installed
		if (!(Get-PSSnapin -Registered -Name $VMwareSnapinName -ErrorAction SilentlyContinue)) {
			Write-Host "Install Vmware PowerCLI"
			Return
			}
		else {
			Add-PSSnapin -Name $VMwareSnapinName
			}
		}

	# Connect to Virtual Center server	
	$Null = Connect-VIServer -Server $vCenter -NotDefault

	# Get list of untrusted (DMZ) port groups
	$UntrustedPortGroups = Get-VirtualPortGroup -Server $vCenter -VirtualSwitch DMZ | Sort Name | Select -Expand Name

	# Get list of VMs and their configured port groups
	$VMList = Get-VM -Server $vCenter | 
		Select Name,
			@{Name='Portgroup';Expression={$_ | Get-NetworkAdapter | Select -Expand NetworkName} }
	#		@{Name='Datastore';Expression={$_ | Get-Datastore | Select -Expand Name } }

	# Initialize list of VMs with multiple connections that include a protected portgroup.  Start with all VMs with multiple NICs and filter
	$FailedVMs = @()

	# Get VMs with multiple NICs
	$FailedVMs += $VMList | Where { ($_.PortGroup.Count -gt 1) }

	# Get VMs with connections in $UntrustedPortGroups
	$FailedVMs = ForEach ($VM in $FailedVMs) {
		ForEach ($PortGroup in $VM.PortGroup) {
			If ($UntrustedPortGroups -Contains $PortGroup) {
				$VM
				}
			}
		}

	# Remove white listed VMs
	$FailedVMs = Foreach ($VM in $FailedVMs) {
		If ($WhiteListVMs -NotContains $VM.Name) {
			$VM
			}
		}

	# Check for storage connectivity violations
	#Foreach ($VM in $VMList) {
		# Get VMs in protected portgroups
		# Validate those VMs are only on "-DMZ-" datastores
	#	}
	}
	
if ($FailedVMs) {
	$EmailSubject += " - Failed"

	$EmailBody = "The following virtual machines on $vCenter failed the DMZ audit.  They are connected to multiple networks "
	$EmailBody += "including one designated as protected.  Please verify their network configuration and make changes as necessary.  "
	$EmailBody += "If this configuration is intentional, add the servername to the whitelist <\\full\path\to\file\share\Audit-DMZVMs.csv.`n"
	$EmailBody += $FailedVMs | Sort -Unique Name | Format-List | Out-String
	$EmailBody += "Ran in $($TimeTaken.TotalSeconds) seconds`n"

 	SendEmail -Server $EmailServer -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody
	}
else {
	$EmailSubject += " - Success"

	$EmailBody = "No DMZ audit failures`n"
	$EmailBody += "Ran in $($TimeTaken.TotalSeconds) seconds`n"
	
 	SendEmail -Server $EmailServer -From $EmailFrom -To $EmailDebugTo -Subject $EmailSubject -Body $EmailBody
	}
	
Disconnect-VIServer -Server $vCenter -Confirm:$False