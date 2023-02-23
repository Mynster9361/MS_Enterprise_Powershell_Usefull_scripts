<#
##################################################################################################################
# Requires: Windows PowerShell Module for Active Directory
##################################################################################################################
##################################################################################################################
# Implementation steps:
##################################################################################################################

Put the following script on your server preferably a server with access to the active directory 
since it needs to be able too look up password expire date.
Logon to Exchange online go to Mailflow go to connections and create a new connection:
EKS:
 	- fx "SMTP Relay for X Server"
	- From "The Organisations mailserver" to Office365
	- Insert the public ip from fx. https://www.whatismyip.com/

Configure the Params in the script below

Create a task in task schedueler
	- Program/Script: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
	- Add Arguements: -Executionpolicy bypass "c:\Scripts\PasswordReminder\PasswordReminder.ps1"
	- No Start in
	- Run at 12.00 every day
	- Run as admin
#>
param(
    $clientID = "",
    $Clientsecret = "",
    $tenantID = "",
    $expireindays = 14,
    $from = "", # Your_friendly_it_person@contoso.com
    $logging = "Enabled", # Set to Disabled to Disable Logging
    $logFile = "c:\scripts\passwordreminderLOG.csv", # ie. c:\mylog.csv
    $testing = "Disabled", # Set to Disabled or enabled to Email Users
    $testRecipient = "", # User1@contoso.com
    $Known_P = "", # Please specify the ammount of passwords in the password policy is it going back and not being allowed to use the last 3 passwords or more
    $P_Length = "", # Please specify minimum length requirement f.eks. 12
    $Minimum_Complexity = "2", # Please select how many of the below needs to be fullfilled in order to live up to password policy
    $P_Compliance = "upper & lower case letters, Numbers and special charaters. Eks. Who1Wants2Coffe3!", # Please specify if you are using advanced
    $Contact = "IT @ phone number XXX XXX XXX" # Specify who they should contact for questions
)
#
###################################################################################################################

# Check Logging Settings
if (($logging) -eq "Enabled") {
    # Test Log File Path
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True") {
        # Create CSV File and Headers
        New-Item $logfile -ItemType File
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn,Notified"
    }
} # End Logging Check

# System Settings
$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -format ddMMyyyy
# End System Settings

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
Import-Module ActiveDirectory
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress | Where-Object { $_.Enabled -eq "True" } | Where-Object { $_.PasswordNeverExpires -eq $false } | Where-Object { $_.passwordexpired -eq $false }
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users) {
    $Name = $user.Name
    $emailaddress = $user.emailaddress
    $passwordSetDate = $user.PasswordLastSet
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)
    $sent = "" # Reset Sent Flag
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null) {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
    else {
        # No FGP set to Domain Default
        $maxPasswordAge = $DefaultmaxPasswordAge
    }

  
    $expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
        
    # Set Greeting based on Number of Days to Expiry.

    # Check Number of Days to Expiry
    $messageDays = $daystoexpire

    if (($messageDays) -gt "1") {
        $messageDays = "in " + "$daystoexpire" + " days."
    }
    else {
        $messageDays = "today."
    }

    # Email Subject Set Here
    $subject = "Your password is going to expire $messageDays"
  
    # Email Body Set Here, Note You can use HTML, including Images.
    $body = "
    Hi $name,
    <p><strong> Your password is going to expire $messageDays</strong><br>
    Please change your password by pressing the following compination on your keyboard<br>
    CTRL+ALT+DELETE <br>
    And Chose Change a password <br>
    Input your old password in the first box and follow it up with a new password of your choosing in the next 2.<br>
    Please note that if you are not at the office you need to be connected to the VPN before chaning your password.<br>
    Once you have changed your password please lock your pc with<br>
    WIN + L<br>
    And unlock it with your new password.<br><br>
    
    Remember our password policy is as follows:<br>
	<li> You are not allowed to use your last $Known_P passwords again. </li> <br>
	<li> Your password minimum length should be $P_Length Characters. </li> <br>
	<li> Your password needs to include at minimum $Minimum_Complexity of these attributes $P_Compliance </li> <br><br>

    This email will be sent everyday untill your password has been changed.
    <br><br><br>
    
    
    For any question regarding this please contact $Contact
    <br><br>"

   
    # If Testing Is Enabled - Email Administrator
    if (($testing) -eq "Enabled") {
        $emailaddress = $testRecipient
    } # End Testing

    # If a user has no email address listed
    if (($emailaddress) -eq $null) {
        $emailaddress = $testRecipient    
    }# End No Valid Email

    # Send Email Message
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays)) {
        $sent = "Yes"
        # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled") {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent" 
        }
        # Send Email Message
        $URLsend = "https://graph.microsoft.com/v1.0/users/$From/sendMail"
        #Connect to GRAPH API
        $tokenBody = @{
            Grant_Type    = "client_credentials"
            Scope         = "https://graph.microsoft.com/.default"
            Client_Id     = $clientId
            Client_Secret = $clientSecret
        }
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $tokenBody
        $headers = @{
            "Authorization" = "Bearer $($tokenResponse.access_token)"
            "Content-type"  = "application/json"
        }

        $mailParams = @{
            Message = @{
                Subject = $subject
                Body    = @{
                    ContentType = "HTML"
                    Content     = $body
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $emailaddress
                        }
                    }
                )
            }
        }

        $Exit = 0
        Do {
            Try {
                # Send Mail
                Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headers -Body ($mailParams | ConvertTo-Json -Depth 5)
                Write-Output "send message"
                $Exit = 8
            }
            Catch {
                $Exit ++
                Write-Output "Failed to send message because: $($Error[0])"
                Write-Output "Try #: $Exit"
                Start-Sleep -Seconds 15
                If ($Exit -eq 8) {   
                    throw "Unable to send message!"
                }
            }
        } Until ($Exit -eq 8)

    } # End Send Message
    else { # Log Non Expiring Password
        $sent = "No"
        # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled") {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent" 
        }        
    }
    
} # End User Processing



# End