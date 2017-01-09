################################################################################################################# 
#  
# Version 1.4 February 2016 
# Robert Pearman  
# Script to Automated Email Reminders when Users Passwords due to Expire. 
# 
# Requires: Windows PowerShell Module for Active Directory 
#
# Change emails December 2016 Scott Abrams
################################################################################################################## 
# Please Configure the following variables.... 
$smtpServer="mail.rockbreaker.com" 
$expireindays = 8 
$from = "RockBreaker HelpDesk <DONOTREPLY@rockbreaker.com>" 
$logging = "Enabled" # Set to Disabled to Disable Logging 
$logFile = "C:\Administration\Scripts\Log\psswdexp.csv" # ie. c:\mylog.csv 
$testing = "Disabled" # Set to Disabled to Email Users 
$testRecipient = "sabrams@rockbreaker.com" 
# 
################################################################################################################### 
 
# Check Logging Settings 
if (($logging) -eq "Enabled") 
{ 
    # Test Log File Path 
    $logfilePath = (Test-Path $logFile) 
    if (($logFilePath) -ne "True") 
    { 
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
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false } 
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge 
 
# Process Each User for Password Expiry 
foreach ($user in $users) 
{ 
    $Name = $user.Name 
    $emailaddress = $user.emailaddress 
    $passwordSetDate = $user.PasswordLastSet 
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user) 
    $sent = "" # Reset Sent Flag 
    # Check for Fine Grained Password 
    if (($PasswordPol) -ne $null) 
    { 
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge 
    } 
    else 
    { 
        # No FGP set to Domain Default 
        $maxPasswordAge = $DefaultmaxPasswordAge 
    } 
 
   
    $expireson = $passwordsetdate + $maxPasswordAge 
    $today = (get-date) 
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days 
         
    # Set Greeting based on Number of Days to Expiry. 
 
    # Check Number of Days to Expiry 
    $messageDays = $daystoexpire 
 
    if (($messageDays) -gt "1") 
    { 
        $messageDays = "in " + "$daystoexpire" + " days." 
    } 
    else 
    { 
        $messageDays = "today." 
    } 
 
    # Email Subject Set Here 
    $subject="Your password will expire $messageDays" 
   
    # Email Body Set Here, Note You can use HTML, including Images. 
    $body =" 
    Dear $name, 
    <p> Your Password will expire $messageDays<br> 
    </p>
    <p>
    To change your password on a PC press CTRL ALT Delete and choose Change Password <br>
    Enter your old Password <br>
    Press Tab <br>
    Enter your new password <br>
    Press Tab <br>
    Re-Enter your new password <br>
    Click OK <br>
    </p>
    <p>
    If your password has already expired... <br>
    Press CTRL ALT DELETE and select Switch User <br>
    Enter your credentials <br>
    It will now ask you to set your new password <br>
    </p>
    <p>Thanks, <br>
    HelpDesk Team  
    </P>" 
 
    
    # If Testing Is Enabled - Email Administrator 
    if (($testing) -eq "Enabled") 
    { 
        $emailaddress = $testRecipient 
    } # End Testing 
 
    # If a user has no email address listed 
    if (($emailaddress) -eq $null) 
    { 
        $emailaddress = $testRecipient     
    }# End No Valid Email 
 
    # Send Email Message 
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays)) 
    { 
        $sent = "Yes" 
        # If Logging is Enabled Log Details 
        if (($logging) -eq "Enabled") 
        { 
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent"  
        } 
        # Send Email Message 
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High -Encoding $textEncoding    
 
    } # End Send Message 
    else # Log Non Expiring Password 
    { 
        $sent = "No" 
        # If Logging is Enabled Log Details 
        if (($logging) -eq "Enabled") 
        { 
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent"  
        }         
    } 
     
} # End User Processing 


$filename = "C:\Administration\Scripts\Log\psswdexp.csv"

# Check the file exists
if (-not(Test-Path $fileName)) {break}

# Display the original name
#"Original filename: $fileName"

$fileObj = get-item $fileName

# Get the date
$DateStamp = get-date -uformat "%Y-%m-%d@%H-%M-%S"

$extOnly = $fileObj.extension

if ($extOnly.length -eq 0) {
   $nameOnly = $fileObj.Name
   rename-item "$fileObj" "$nameOnly-$DateStamp"
   }
else {
   $nameOnly = $fileObj.Name.Replace( $fileObj.Extension,'')
   rename-item "$fileName" "$nameOnly-$DateStamp$extOnly"
   }

# Display the new name
#"New filename: $nameOnly-$DateStamp$extOnly"
 
 
 
# End