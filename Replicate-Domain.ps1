# Sync-Domain
# 	-Domain		Domain to sync
#	-Site		Site to sync
#	-List		List sites and domains

param(
	$Domain,
	$Site,
	[Switch] $AllSites,
	[Switch] $List,
	[Switch] $Help
	)

if ($Help) {
	Write-Host "Sync-Domain"
	Write-Host "	-Domain		(Optional) Domain to sync"
	Write-Host "	-Site		(Optional) Site to sync"
	Write-Host "	-AllSites	(Optional) Replicate domain controllers across all sites"
	Write-Host "	-List		(Optional) List sites and domains"
	Return
	}
	
If ($List) {
	$ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest")
	$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

	# List Sites
	$SiteNames = $Forest | Select -Expand Sites 
	Write-Host "Sites:"
	$SiteNames | % { Write-Host "	$($_.Name)" }
	
	Write-Host
	
	# List Domains
	$DomainNames = $Forest | Select -Expand Domains
	Write-Host "Domains:"
	$DomainNames | % { Write-Host "	$($_.Name)" }
	Return
	}
	
if ($Domain) {
	$DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$Domain)
	$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
	}
else {
	$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
	}
	
if ($Site) {
	$ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest")
	$Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::FindByName($ForestContext, $Site)
	}
else {
	$Site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()
	}

if ($AllSites) {
	$DCs = $Domain.FindAllDomainControllers()
	}
else {
		$DCs = $Domain.FindAllDomainControllers($Site.Name)
	
	}

$DCs | % {
	Write-Host "Replicating $($_.Name) ... " -NoNewLine
	$null = repadmin /kcc $_.Name
	$null = repadmin /syncall /A $_.Name
	Write-Host "Done"
	}