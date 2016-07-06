Get-PSSNapin -Registered | Add-PSSnapin
[void][System.Reflection.Assembly]::LoadWithPartialName("VMware.Vim")
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')

$global:hostname = $null
$defaultExchangeServer = "exchserver.fabrikam.com" #update this
$defaultExchangeSub = $defaultExchangeServer.SubString(0,$defaultExchangeServer.IndexOf("."))
$ExchangeProduct = "Exchange 2010"
$defaultLyncServer = "null"
$vSphereCLIProduct = "vSphere PowerCLI"
set-alias Get-VIServer Connect-VIServer
set-alias Get-VC Connect-VIServer
set-alias Get-ESX Connect-VIServer

function prompt 
{ 
	if($global:hostname -eq $null) {$global:hostname = $(hostname)}
	$cwd = (get-location).Path
	$dnsname = (get-qadrootdse).domain.dnsname
	
	#change title bar text
    $title = "[$global:hostname] :: AD [$dnsname] :: $ExchangeProduct [Not Connected] :: $vSphereCLIProduct [Not Connected]"
	$host.ui.rawui.WindowTitle = $title
	
    if(Get-PSSession -Name $defaultExchangeServer -ErrorAction SilentlyContinue){
		if(($DefaultVIServer -ne $null) -and ($DefaultVIServer.IsConnected) ){
			$title = "[$global:hostname] :: AD [$dnsname] :: $ExchangeProduct [" + $defaultExchangeSub + "] :: $vSphereCLIProduct [" + $DefaultVIServer.Name + " as " + $DefaultVIServer.User + "]"
			$host.ui.rawui.WindowTitle = $title
			# change prompt text
			Write-Host "[$("{0:M/d H:mm:ss}" -f (Get-Date))" -NoNewLine -foregroundcolor Cyan
			Write-Host ".Exch2010" -NoNewLine -foregroundcolor White
			Write-Host ".$($DefaultVIServer.Name)-] " -NoNewLine -foregroundcolor Green
			Write-Host ((Get-location).Path + ">") -NoNewLine
			return " "
		}
		else{
			$title = "[$global:hostname] :: AD [$dnsname] :: $ExchangeProduct [" + $defaultExchangeSub + "] :: +  $vSphereCLIProduct [Not Connected]"
			$host.ui.rawui.WindowTitle = $title
			# change prompt text
			Write-Host "[$("{0:M/d H:mm:ss}" -f (Get-Date))" -NoNewLine -foregroundcolor Cyan
			Write-Host ".Exch2010] " -NoNewLine -foregroundcolor White
			Write-Host ((Get-location).Path + ">") -NoNewLine
			return " "
		}
	}
	else{
		if(($DefaultVIServer -ne $null) -and ($DefaultVIServer.IsConnected) ){
			$title = "[$global:hostname] :: AD [$dnsname] :: $ExchangeProduct [Not Connected] :: $vSphereCLIProduct [" + $DefaultVIServer.Name + " as " + $DefaultVIServer.User + "]"
			$host.ui.rawui.WindowTitle = $title
			# change prompt text
			Write-Host "[$("{0:M/d H:mm:ss}" -f (Get-Date))" -NoNewLine -foregroundcolor Cyan
			Write-Host ".$($DefaultVIServer.Name)-] " -NoNewLine -foregroundcolor Green
			Write-Host ((Get-location).Path + ">") -NoNewLine
			return " "		
		}
	}
    
	Write-Host "[$("{0:M/d H:mm:ss}" -f (Get-Date))-" -NoNewLine -foregroundcolor Cyan
	$host.UI.Write("Cyan", $host.UI.RawUI.BackGroundColor, "PS]")
	" $cwd>" 
}

function Exchange2010-PSSession{
	Param ($exchServer=$defaultExchangeServer)
	$Exchange2010Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$exchServer/PowerShell/ -Authentication Kerberos -Credential $(Get-Credential -Message "domain Exchange" -UserName "netbios\$($env:username)") -Name $exchServer
	Import-PSSession $Exchange2010Session -AllowClobber
}

function Office365-PSSession{
	#Param ($exchServer=$defaultExchangeServer)
	$o365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $(Get-Credential -Message "Office 365 Admin" -UserName "$upnprefix@fabrikam.onmicrosoft.com") -Authentication Basic -AllowRedirection -Name Office365 
	Import-PSSession $o365Session -AllowClobber
}

#function Manage-Lync2010-PSSession{
#	$lync2010Options = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
#	$lync2010Session = New-PSSession -ConnectionUri https://$defaultLyncServer/OcsPowerShell -SessionOption $lync2010Options -Authentication NegotiateWithImplicitCredential
#	Import-PSSession $lync2010Session
#}

# open documentation file
function Get-VIToolkitDocumentation{
   $regKeys = Get-ItemProperty "hklm:\software\VMware, Inc.\VMware VI Toolkit (for Windows)" -ErrorAction SilentlyContinue
   
   #64bit os fix
   if($regKeys -eq $null){
      $regKeys = Get-ItemProperty "hklm:\software\wow6432node\VMware, Inc.\VMware VI Toolkit (for Windows)"  -ErrorAction SilentlyContinue
   }

   $ChmFilePath = $regKeys.InstallPath + "$vSphereCLIProduct Cmdlets Reference.chm"
   $docProcess = [System.Diagnostics.Process]::Start($ChmFilePath)
}

# open toolkit community url with default browser
function Get-VIToolkitCommunity{
    $link = "http://communities.vmware.com/community/developer/windows_toolkit"
    $browserProcess = [System.Diagnostics.Process]::Start($link)
}

function Get-VICommand() {
  get-command -pssnapin VMware.VimAutomation.Core
}

function New-DatastoreDrive([string] $Name, $Datastore){
	begin {
		if ($Datastore) {
			Write-Output $Datastore | New-DatastoreDrive -Name $Name
		}
	}
	process {
		if ($_) {
			$ds = $_
			New-PSDrive -Name $Name -Root \ -PSProvider VimDatastore -Datastore $ds -Scope global
		}
	}
	end {
	}
}

function New-VIInventoryDrive([string] $Name, $Location){
	begin {
		if ($Location) {
			Write-Output $Location | New-VIInventoryDrive -Name $Name
		}
	}
	process {
		if ($_) {
			$location = $_
			New-PSDrive -Name $name -Root \ -PSProvider VimInventory -Location $location -Scope global
		}
	}
	end {
	}
}

function OpenURL([string] $url)
{
	$ie = new-object -comobject "InternetExplorer.Application"
	$ie.visible = $true
	$ie.navigate($url)
}

## only returns Active Roles commands 
function get-qcommand
{
	if ($args[0] -eq $null)
	{
		get-command -pssnapin Quest.ActiveRoles*
	}
	else
	{
		get-command $args[0] | where { $_.psSnapin -ilike 'Quest.ActiveRoles*' }
	}
}

function Get-QARSProductInfo
{
	OpenURL('http://www.quest.com/activeroles-server/')
}

function Get-QARSCommunity
{
	OpenURL('http://activeroles.inside.quest.com/forum.jspa?forumID=262')
}

function get-Banner
{
	write-host "`nWelcome to PowerShell v2 - The following PSSnapins are active for this session`n" -fore White
	
	write-host $snapins -fore white
	
	write-host " View ActiveRoles Server product page:         " -no
	write-host -fore Yellow "Get-QARSProductInfo"
	write-host " List only AD Management Shell cmdlets:        " -no
	write-host -fore Yellow "Get-QCommand"	
	write-host "" 
	
	write-host " Documentation for all available VM commands:  " -NoNewLine
	write-host "Get-VIToolkitDocumentation" -foregroundcolor green  
	write-host " Log in to a vCenter Server or ESX host:       " -NoNewLine
	write-host "Connect-VIServer" -foregroundcolor green
	write-host " List vSphere commands :                       " -NoNewLine
	write-host "Get-VICommand" -foregroundcolor green
	write-host ""
	
	$spaces = 46 - $(" Manage Exchange 2010: $defaultExchangeSub :").length
	write-host " Manage Exchange 2010: $defaultExchangeSub :" $(" " * $spaces) -no
	write-host -fore Cyan "Exchange2010-PSSession`n"	
	
	write-host " List all cmdlets:                             " -no 
	write-host -fore White "Get-Command"
	write-host " View help about a cmdlet:                     " -no
	write-host -fore White "Get-Help <cmdlet-name> or <cmdlet-name> -?"		
	write-host ""
	
	
	
	write-host " View this banner again:                       " -no
	write-host -fore White "Get-Banner`n"	
}
$snapins = ""
Get-PSSnapin | ?{!($_.name -match "microsoft")} | %{$snapins += " $($_.name)`n"}
$upn = get-qaduser $env:username | select -expand userprincipalname
$upnprefix = $upn.SubString(0,$upn.IndexOf("@"))

#Set WindowSize
$hostUI = (Get-Host).UI.RawUI

$buffer = $hostUI.BufferSize
$buffer.width = 300
$buffer.height = 3000
$hostUI.BufferSize = $buffer

$winSize = $hostUI.WindowSize
$winSize.width = 150
$winSize.height = 50
$hostUI.WindowSize = $winSize

$buffer = $hostUI.BufferSize
$buffer.width = 150
$buffer.height = 3000
$hostUI.BufferSize = $buffer

get-Banner
#Exchange2010-PSSession
#cd c:\pscripts\
# SIG # Begin signature block
# MIISdQYJKoZIhvcNAQcCoIISZjCCEmICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgy+XPBlqPhYMH7WI5Rd2XtEK
# 8zGggg5aMIIDTjCCAregAwIBAgIBCjANBgkqhkiG9w0BAQUFADCBzjELMAkGA1UE
# BhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTESMBAGA1UEBxMJQ2FwZSBUb3du
# MR0wGwYDVQQKExRUaGF3dGUgQ29uc3VsdGluZyBjYzEoMCYGA1UECxMfQ2VydGlm
# aWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjEhMB8GA1UEAxMYVGhhd3RlIFByZW1p
# dW0gU2VydmVyIENBMSgwJgYJKoZIhvcNAQkBFhlwcmVtaXVtLXNlcnZlckB0aGF3
# dGUuY29tMB4XDTAzMDgwNjAwMDAwMFoXDTEzMDgwNTIzNTk1OVowVTELMAkGA1UE
# BhMCWkExJTAjBgNVBAoTHFRoYXd0ZSBDb25zdWx0aW5nIChQdHkpIEx0ZC4xHzAd
# BgNVBAMTFlRoYXd0ZSBDb2RlIFNpZ25pbmcgQ0EwgZ8wDQYJKoZIhvcNAQEBBQAD
# gY0AMIGJAoGBAMa4uSdgrwvjkWll236N7ZHmqvG+1e3+bdQsf9Fwd/smmVe03T8w
# uNwh6miNgZL8LkuRNYQg8tpKurT85tqI8iDFIZIJR5WgCRymeb6xTB388YpuVNJp
# ofFMkzpB/n3UZHtjRfdgYB0xHaTp0w+L+24mJLOo/+XlkNS0wtxQYK5ZAgMBAAGj
# gbMwgbAwEgYDVR0TAQH/BAgwBgEB/wIBADBABgNVHR8EOTA3MDWgM6Axhi9odHRw
# Oi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlUHJlbWl1bVNlcnZlckNBLmNybDAdBgNV
# HSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgEGMCkGA1Ud
# EQQiMCCkHjAcMRowGAYDVQQDExFQcml2YXRlTGFiZWwyLTE0NDANBgkqhkiG9w0B
# AQUFAAOBgQB2spzuE58b9i00kpRFczTcjmsuXPxMfYnrw2jx15kPLh0XyLUWi77N
# igUG8hlJOgNbBckgjm1S4XaBoMNliiJn5BxTUzdGv7zXL+t7ntAURWxAIQjiXXV2
# ZjAe9N+Cii+986IMvx3bnxSimnI3TbB3SOhKPwnOVRks7+YHJOGv7DCCA3owggJi
# oAMCAQICEDgl1/r4Ya+e9JDnJrXWWtUwDQYJKoZIhvcNAQEFBQAwUzELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMSswKQYDVQQDEyJWZXJpU2ln
# biBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBMB4XDTA3MDYxNTAwMDAwMFoXDTEy
# MDYxNDIzNTk1OVowXDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJ
# bmMuMTQwMgYDVQQDEytWZXJpU2lnbiBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNp
# Z25lciAtIEcyMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEtfJSFbyIhmAp
# FkpbL0uRa4eR8zVUWDXq0TZeYk1SUTRxwntmHYnI3SrEagr2N9mYdJH2kq6wtXaW
# 8alKY0VHLmsLkk5LK4zuWEqL1AfkGiz4gqpY2c1C8y3Add6Nq8eOHZpsTAiVHt7b
# 72fhcsJJwp5gPOHivhajY3hpFHutLQIDAQABo4HEMIHBMDQGCCsGAQUFBwEBBCgw
# JjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AudmVyaXNpZ24uY29tMAwGA1UdEwEB
# /wQCMAAwMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC52ZXJpc2lnbi5jb20v
# dHNzLWNhLmNybDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
# BsAwHgYDVR0RBBcwFaQTMBExDzANBgNVBAMTBlRTQTEtMjANBgkqhkiG9w0BAQUF
# AAOCAQEAUMVLyCSA3+QNJMLeGrGhAqGmgi0MgxWBNwqCDiywWhdhtdgF/ojb8ZGR
# s1YaQKbrkr44ObB1NnQ6mE/kN7qZicqVQh2wucegjVfg+tVkBEI1TgHRM6IXyE2q
# J8fy4YZMAjhNg3jG/FPg6+AGh92klp5eDJjipb6/goXDYOHfrSjYx6VLZNrHG1u9
# rDkI1TgioTOLL4qa67wHIT9EQQkHtWUcJLxI00SA66HPyQK0FM9UxxajgFz5eT5d
# cn2IF54sQ6LKU859PfYqOrhPlAClbQqDXfleU/QYs1cPcMP79a2VoA4X3sQWgGDJ
# DytuhgTx6/R4J9EFxe40W165STLyMzCCA74wggMnoAMCAQICEEK9QurJYR69yosC
# j47I2AwwDQYJKoZIhvcNAQEFBQAwVTELMAkGA1UEBhMCWkExJTAjBgNVBAoTHFRo
# YXd0ZSBDb25zdWx0aW5nIChQdHkpIEx0ZC4xHzAdBgNVBAMTFlRoYXd0ZSBDb2Rl
# IFNpZ25pbmcgQ0EwHhcNMDgwNDIzMDAwMDAwWhcNMTAwNDIzMjM1OTU5WjCBhjEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFDASBgNVBAcMC0FsaXNv
# IFZpZWpvMR0wGwYDVQQKDBRRdWVzdCBTb2Z0d2FyZSwgSW5jLjEOMAwGA1UECwwF
# UiZEMTUxHTAbBgNVBAMMFFF1ZXN0IFNvZnR3YXJlLCBJbmMuMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnVQWzB+X+jadZIaGi5iBlqwrJS4uyHy80Q/F
# iadZeX1BpueA2wFAwY8V3bxz9nIooib/0J9KHUbmjUuK0DO+h3KxWAskIZEyi+TK
# 8XqXwtiFk0UqDfqHvVJGaIfK/4XLow7UYWDmJD/sgf9UzTqKI1przQf8nrH+7Ixr
# hZgc9N0hblcCwaYIDqpbpFXG45jxQdT16FaO8RmOSnb8LvkJUvmn0hMdaxLEdY94
# OdebiOLqEukd4Vihuj79p6e5mC4SSxU/kM0GUo3ghsoCDT+XlGs4Rbkzdq4WJ9+l
# VfRQTn3L6yjqgQWlfF4/cpp6NqXog9I+gsyMYmnPcn+MSNiEqwIDAQABo4HYMIHV
# MAwGA1UdEwEB/wQCMAAwPgYDVR0fBDcwNTAzoDGgL4YtaHR0cDovL2NybC50aGF3
# dGUuY29tL1RoYXd0ZUNvZGVTaWduaW5nQ0EuY3JsMB8GA1UdJQQYMBYGCCsGAQUF
# BwMDBgorBgEEAYI3AgEWMB0GA1UdBAQWMBQwDjAMBgorBgEEAYI3AgEWAwIHgDAy
# BggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9vY3NwLnRoYXd0ZS5j
# b20wEQYJYIZIAYb4QgEBBAQDAgQQMA0GCSqGSIb3DQEBBQUAA4GBAK1MrOrqcN7h
# mL5TdO/p/PKmLs/qGucAHI7+UG7m/RDGrMJ+C5uVVQoq3y87CdMNK2oEm3lfRPO/
# xkMSXbUm0U1XxW6DXcKiRf8u6usA8klELVJprs/jDySqh4G/dHE3rHbhVgZTR80m
# Xd3ptzgE7pX6Tk+xhtmdvXwGmqGkgH/YMIIDxDCCAy2gAwIBAgIQR78Zld+NUkZD
# 99ttSA0xpDANBgkqhkiG9w0BAQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgT
# DFdlc3Rlcm4gQ2FwZTEUMBIGA1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRo
# YXd0ZTEdMBsGA1UECxMUVGhhd3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRo
# YXd0ZSBUaW1lc3RhbXBpbmcgQ0EwHhcNMDMxMjA0MDAwMDAwWhcNMTMxMjAzMjM1
# OTU5WjBTMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xKzAp
# BgNVBAMTIlZlcmlTaWduIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpyrKkzM0grwp9iayHdfC0TvHfwQ+/
# Z2G9o2Qc2rv5yjOrhDCJWH6M22vdNp4Pv9HsePJ3pn5vPL+Trw26aPRslMq9Ui2r
# SD31ttVdXxsCn/ovax6k96OaphrIAuF/TFLjDmDsQBx+uQ3eP8e034e9X3pqMS4D
# mYETqEcgzjFzDVctzXg0M5USmRK53mgvqubjwoqMKsOLIYdmvYNYV291vzyqJodd
# yhAVPJ+E6lTBCm7E/sVK3bkHEZcifNs+J9EeeOyfMcnx5iIZ28SzR0OaGl+gHpDk
# XvXufPF9q2IBj/VNC97QIlaolc2uiHau7roN8+RN2aD7aKCuFDuzh8G7AgMBAAGj
# gdswgdgwNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC52
# ZXJpc2lnbi5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADBBBgNVHR8EOjA4MDagNKAy
# hjBodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9UaGF3dGVUaW1lc3RhbXBpbmdDQS5j
# cmwwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgEGMCQGA1UdEQQd
# MBukGTAXMRUwEwYDVQQDEwxUU0EyMDQ4LTEtNTMwDQYJKoZIhvcNAQEFBQADgYEA
# Smv56ljCRBwxiXmZK5a/gqwB1hxMzbCKWG7fCCmjXsjKkxPnBFIN70cnLwA4sOTJ
# k06a1CJiFfc/NyFPcDGA8Ys4h7Po6JcA/s9Vlk4k0qknTnqut2FB8yrO58nZXt27
# K4U+tZ212eFX/760xX71zwye8Jf+K9M7UhsbOCf3P0oxggOFMIIDgQIBATBpMFUx
# CzAJBgNVBAYTAlpBMSUwIwYDVQQKExxUaGF3dGUgQ29uc3VsdGluZyAoUHR5KSBM
# dGQuMR8wHQYDVQQDExZUaGF3dGUgQ29kZSBTaWduaW5nIENBAhBCvULqyWEevcqL
# Ao+OyNgMMAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFjAj
# BgkqhkiG9w0BCQQxFgQU7XOW9OsgH30gz/3E3dv8PrXC7uIwDQYJKoZIhvcNAQEB
# BQAEggEAV4oHX83l8t9HlJVMq3s/gOuvwVCux4n03AcZGhFSifSrIWQ3nPs/bT5I
# 0MW72VSenW27HVE5xSVLyqyp8rWsZ7oAZNukSrgXINpE8sThsn0TXY+wCV9TdHgy
# bq++L2QZIVDbPQMkyVOQSiPLJ7qSHYuyXxa5K+Hdab14PlE9s4uIuLAUeNhmLe3L
# K3Paa+PasgQJhp1SqTy63fNd+bF4sEcUelyJz6hevypoxP6IF/yjTmdauIOuz6fR
# iqlQVsEOdOCfQo48alKYEV2mnjYOB/MsO5eAn6yoP3DyIjHOp2jB/Qyc3F0SKTNu
# f9yPl2PAvUK+ATWaxS3OG9s9CNnaqKGCAX8wggF7BgkqhkiG9w0BCQYxggFsMIIB
# aAIBATBnMFMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEr
# MCkGA1UEAxMiVmVyaVNpZ24gVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQQIQOCXX
# +vhhr570kOcmtdZa1TAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMDkxMTE0MDMzNzMxWjAjBgkqhkiG9w0BCQQx
# FgQUCQD47KKoMM4GTXLk0KUNNAI8txYwDQYJKoZIhvcNAQEBBQAEgYC0acHNiCEK
# ACm+nJD8WuzApgs8WkrgCf/CYr7MwUf4JVqHj4thCLogX2xW50FDe6RlDgUSM3qs
# 32sJxmMEs0qCTKVSaY7jaqw16jl9S4bsjLQfUQ3qbQ61vThw8YtLvU1WeI9h+5Sd
# 670lHA32RMrTZS1sdKTubfBgYSUJIP58Rw==
# SIG # End signature block
