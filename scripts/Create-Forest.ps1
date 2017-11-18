# Here we install the windows items necessary to make ADDS work
Install-WindowsFeature AD-Domain-Services

Install-ADDSForest -DomainName laforge.com -InstallDNS:$false -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "L4f0rGeEx@Mpl3" -Force) -Confirm:$false

Start-Sleep -s 12

restart-computer -Force

Start-Sleep -s 60
