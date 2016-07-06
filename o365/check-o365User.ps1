Param($users, $msolCred, $srcCred, $tgtCred, [switch]$Verbose)

Add-PSSnapin Quest* -ErrorAction SilentlyContinue

#variables

$targetDomain = "contoso.com"
$sourceDomain = "fabrikam.com"
$proxyAddrMatch = $sourceDomain

#if(!$srcCred) { $srcCred = get-credential -message "$sourceDomain"}
#if(!$tgtCred) { $tgtCred = get-credential -message "$targetDomain"}
if(!$msolCred) { $msolCred = get-credential -message "Microsoft Online"}
if(!$users){
	Write-Host
	Write-Host "No users specified ... retrieving all licensed Office 365 users that match proxyAddress $proxyAddrMatch" -Fore Cyan
	Write-Host
	$null = Connect-MsolService -credential $msolCred
	$users = Get-MsolUser -all | ?{$_.isLicensed -and $_.proxyaddresses -match $proxyAddrMatch} | select -expand UserPrincipalName
}

foreach($user in $users){
	if($user){
		$userError = $false
		write-host
		write-Host "Checking $user ... " -Fore White -NoNewLine
		
		#check MSOL
		$null = Connect-MsolService -credential $msolCred
		if ( ($(Get-MsolUser -UserPrincipalName $user | measure).count -eq 1) ) {
			$msolUser    = Get-MsolUser -UserPrincipalName $user
			$msolDisplay = $msolUser.DisplayName
			$msolImID    = $msolUser.ImmutableID
			$msolIsLic   = $msolUser.IsLicensed
			$msolSignIn  = $msolUser.SignInName
			$msolPWLS	 = $msolUser.LastPasswordChangeTimestamp
			$msolPWNE	 = $msolUser.PasswordNeverExpires
			$msolUPN     = $msolUser.UserPrincipalName
		}
		else { $userError=$true; write-host; write-host "Get-MSOLUser -UserPrincipalName $user returned no results - user can't be found" -fore RED }

		#check targetDomain
		$null = connect-qadservice $targetDomain
		if ( $(get-qaduser $user | measure).count -eq 1 ) {
			$tgtUser   = get-qaduser $user -includeAllProperties
			$tgtSam    = $tgtUser.samaccountname
			$tgtUPN    = $tgtUser.UserPrincipalName
			$tgtExt11  = $tgtUser.extensionAttribute11
			$tgtExt12  = $tgtUser.extensionAttribute12
			$tgtExt13  = $tgtUser.extensionAttribute13
			$tgtExt14  = $tgtUser.extensionAttribute14
			$tgtPWLS   = $tgtUser.PasswordLastSet
			$tgtPWExp  = $tgtUser.PasswordIsExpired
			$tgtPWExD  = $tgtUser.PasswordExpires
			$tgtPWStat = $tgtUser.PasswordStatus
			$tgtUMCP   = $tgtUser.UserMustChangePassword
			$tgtEmail  = $tgtUser.email
			$tgtPSMTP  = $tgtUser.PrimarySMTPAddress
		}
		else { $userError=$true; write-host; write-host "More than one or user not found for $user in $targetDomain be more specific" -fore RED }
		
		#Check sourceDomain
		$null = connect-qadservice $sourceDomain
		if ( $(get-qaduser $tgtSAM | measure).count -eq 1 ) {
			$srcUser   = get-qaduser $tgtSAM -includeAllProperties
			$srcSam    = $srcUser.samaccountname
			$srcUPN    = $srcUser.UserPrincipalName
			$srcExt11  = $srcUser.extensionAttribute11
			$srcExt12  = $srcUser.extensionAttribute12
			$srcExt13  = $srcUser.extensionAttribute13
			$srcExt14  = $srcUser.extensionAttribute14
			$srcPWLS   = $srcUser.PasswordLastSet
			$srcPWExp  = $srcUser.PasswordIsExpired
			$srcPWExD  = $srcUser.PasswordExpires
			$srcPWStat = $srcUser.PasswordStatus
			$srcUMCP   = $srcUser.UserMustChangePassword
			$srcEmail  = $srcUser.email
			$srcPSMTP  = $srcUser.PrimarySMTPAddress
		}
		else { $userError=$true; write-host; write-host "More than one or user not found for $user in $sourceDomain be more specific" -fore RED }

		

		
		if($userError){ Write-Host "Error Encountered ... skipping report" -Fore Red }
		else {
		
			if($srcSAM -eq $tgtSAM){ write-host "." -Fore Green -NoNewLine }
			else{ 
				write-host; 
				write-host "sAMAccountName doesn't match between $sourceDomain and $targetDomain" -Fore RED
				write-host "    $srcSAM <> $tgtSAM" -Fore RED 
			}
			
			if($srcUPN -eq $tgtUPN -and $tgtUPN -eq $msolUPN){ write-host "." -Fore Green -NoNewLine }
			else { 
				write-host;
				Write-Host "UPN doesn't match" -Fore Red
				if($srcUPN -ne $msolUPN){ Write-Host "    source: $srcUPN" -Fore Red } else { Write-Host "    source: $srcUPN" -Fore Green }
				if($tgtUPN -ne $msolUPN){ Write-Host "    source: $tgtUPN" -Fore Red } else { Write-Host "    source: $tgtUPN" -Fore Green }
				Write-Host "      o365: $msolUPN" -Fore Green
			}
			
			if($tgtExt12 -eq "SyncWithMailbox"){ write-host "." -Fore Green -NoNewLine }
			else { 
				write-host;
				Write-Host "Extension12 in $targetDomain not set properly for migrated user" -Fore Red
				write-host "    extensionAttribute12: $tgtExt12" -Fore Red }
			
			if($srcPSMTP -eq $tgtPSMTP -and $tgtPSMTP -eq $msolUPN -and $srcPSMTP -eq $tgtUPN -and $srcUPN -eq $tgtPSMTP){ write-host "." -Fore Green -NoNewLine }
			else{ 
				write-host;
				write-host "Primary SMTP doesn't match UPN" -Fore Red
				write-host "    source Primary SMTP: $srcPSMTP" -Fore Red
				write-host "             source UPN: $srcUPN" -Fore RED
				write-host "    target Primary SMTP: $tgtPSMTP" -Fore Red
				write-host "             target UPN: $tgtUPN" -Fore RED
				write-host "         Office 365 UPN: $msolUPN" -fore Red
			}
			
			if($srcExt13 -eq $tgtExt13 -and $tgtExt13 -eq $msolImID){ write-host "." -Fore Green -NoNewLine }
			else { 
				write-host;
				write-host "ImmutableID doesn't match "
				write-host "    source extensionAttribute13: $srcExt13" -Fore Red
				write-host "    target extensionAttribute13: $tgtExt13" -Fore Red
				write-host "         Office 365 ImmutableID: $msolImID" -Fore Green
			}
			
			if($srcExt14 -eq $tgtExt14 -and $tgtExt14 -eq "True"){ write-host ". Fully Migrated." -Fore Green }
			else{  
				write-host " Partially Migrated" -Fore Cyan
				write-host "Office 365 will use $sourceDomain for SSO authentication: " -fore Cyan
				write-host "    source extensionAttribute14: $srcExt14" -fore Cyan
				write-host "    target extensionAttribute14: $tgtext14" -fore Cyan
			}
			
			if($srcPWExp -or $tgtPWExp -or $tgtUMCP -or $srcUMCP){
				if($srcPWExp -or $srcUMCP){ 
				write-host "   sourceDomain PasswordStatus : $srcPWStat" -Fore Red }
				else{ 
				write-host "   sourceDomain PasswordStatus : $srcPWStat" -Fore Green }
				if($tgtPWExp -or $tgtUMCP){ 
				write-host "   targetDomain PasswordStatus : $tgtPWStat" -Fore Red }
				else{ 
				write-host "   targetDomain PasswordStatus : $tgtPWStat" -Fore Green }
			} else {
				if( ($srcPWExD - $(get-date)).days -le 15 ){
				write-host "   sourceDomain PasswordStatus : $srcPWStat - within 15 days" -Fore Yellow }
				else { 
				write-host "   sourceDomain PasswordStatus : $srcPWStat" -Fore Green }
				if( ($tgtPWExD - $(get-date)).days -le 15 ){
				write-host "   targetDomain PasswordStatus : $tgtPWStat - within 15 days" -Fore Yellow }
				else { 
				write-host "   targetDomain PasswordStatus : $tgtPWStat" -Fore Green }
			}
			write-host
		}

		if($verbose){
			write-host "Verbose Output: " -Fore Yellow
			write-host "          source sAMAccountName : $srcSAM"
			write-host "          target sAMAccountName : $tgtSAM"
			Write-Host "       source UserPrincipalName : $srcUPN"
			Write-Host "       target UserPrincipalName : $tgtUPN"
			Write-Host "         o365 UserPrincipalName : $msolUPN"
			write-host "    target extensionAttribute12 : $tgtExt12"
			write-host "            source Primary SMTP : $srcPSMTP"
			write-host "                     source UPN : $srcUPN"
			write-host "            target Primary SMTP : $tgtPSMTP"
			write-host "                     target UPN : $tgtUPN"
			write-host "                 Office 365 UPN : $msolUPN"
			write-host "    source extensionAttribute13 : $srcExt13"
			write-host "    target extensionAttribute13 : $tgtExt13"
			write-host "         Office 365 ImmutableID : $msolImID"
			write-host "    source extensionAttribute14 : $srcExt14"
			write-host "    target extensionAttribute14 : $tgtext14"
			write-host "         source PasswordLastSet : $srcPWLS"
			write-host "         target PasswordLastSet : $tgtPWLS"
			write-host "            o365PasswordLastSet : $msolPWLS"
			write-host "       o365PasswordNeverExpires : $msolPWNE"
			write-host "    sourceDomain PasswordStatus : $srcPWStat"
			write-host "    targetDomain PasswordStatus : $tgtPWStat"
			write-host
		}
	}
}