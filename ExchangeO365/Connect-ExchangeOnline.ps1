# To have the script be automated you can configure sign in with certificate like descriped here:
# https://docs.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps
# I would suggest and recommend to use "Connect using a certificate thumbprint:"

Connect-ExchangeOnline -CertificateThumbPrint "" -AppID "" -Organization ""
