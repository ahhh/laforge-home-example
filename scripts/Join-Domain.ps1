# Simple PowerShell script to join machine to the domain
$pass = ConvertTo-SecureString "L4f0rGeEx@Mpl3" -asPlainText -Force
$user = "LAFORGE\Administrator"
$creds = New-Object System.Management.Automation.PSCredential($user,$pass)
Add-Computer -DomainName laforge.com -Credential $creds
Restart-Computer
