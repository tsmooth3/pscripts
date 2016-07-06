###################################################################
### Library of Custom Email Functions
###################################################################

### STANDARD SMTP MESSAGE ###
function Sendmail ($to, $from, $subject, $body, $smtpserver)
{
	[int]$error_sendmail = 3
	
	#Create Message
	$smtp_message = New-Object System.Net.Mail.MailMessage

	$smtp_message.To.Add($to)
	$smtp_message.From = $from
	$smtp_message.Subject = $subject
	$smtp_message.Body = $body
	
	$smtp_server = $smtpserver
	$client = New-Object System.Net.Mail.SmtpClient ($smtp_server)
	
	try
	{
		# Write-Host "Successful Email Send"
		$client.Send($smtp_message)
		$error_sendmail = 0
	}
	catch
	{
		#Write-Host "Error Sending SMTP Message"
		$error_sendmail = 1
	}
	
	return $error_sendmail
}
