# Configuration
$TenantID = "kl76e9b0-cb9d-4345-9fa6-Fgn7kEou8"
$ClientID = "e8df482b-c7c6-49e6-ggh76-099uYtew" 
$ClientSecret = "Q7e8Q~48B3GsPHiw-Njdq-rtpK56SE"


# Convert the client secret to a secure string
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Create a credential object using the client ID and secure string
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretPass

# Connect to Microsoft Graph with Client Secret
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

# Set the notification threshold - days before password expires
$NotificationThreshold = 7
$PasswordExpiryThreshold = 60 #By default 90 days Password expiry
 
# Get all users
$AllUsers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName,Mail,UserType, AccountEnabled,PasswordPolicies,lastPasswordChangeDateTime


$SenderID = "soporte@365cloud.cl"

ForEach ($User in $AllUsers)
{
    # Skip disabled accounts and users with Password never Expire flag
    If (!$User.AccountEnabled -or $User.PasswordPolicies -contains "xDisablePasswordExpiration" -or $User.userType -eq "Guest") {
        continue
    }
 
    # Get user's password Expiry Date
    $PasswordExpiryDate = $User.lastPasswordChangeDateTime.AddDays($PasswordExpiryThreshold)
 
    # Calculate the remaining days
    $RemainingDays = ($PasswordExpiryDate - (Get-Date)).Days
 
    # Check if the remaining days are within the notification threshold
    If ($RemainingDays -le $NotificationThreshold) {
        # Send an email notification to the user
        $EmailBody = "
            Estimado $($User.DisplayName),
            <br/><br/>
            su contraseña expirará dentro de los siguientes $remainingDays dias. Le solicitamos realizar el cambio a la brevedad para evitar perder acceso a sus servicios.
            <br/><br/>
            Link para cambio de contraseña:<br/>
            <ol>
            https://account.activedirectory.windowsazure.com/ChangePassword.aspx<br/></ol>

<ol>
            <b>La contraseña debe cumplir los requisitos de complejidad:</b>
            <li>- Una extensión de mínimo 12 caracteres.</li>
            <li>- Incluir mayúsculas y minúsculas.</li>
            <li>- Alfanumérico (letras y números).</li>
            <li>- Incluir caracteres especiales</li>
            </ol>
            
 <ol>
            <b> Recomendaciones:</b>
<li>-No use una contraseña igual o similar a una que use en otros sitios web.</li>
<li>-Use combinacion de palabras</li>
</ol>
<br/>
 Saludos.
Area de Soporte

            
        "
 
    $MailParams = @{
        Message = @{
            Subject = "Su clave de correo expirara pronto"
            Importance = "High"
            Body = @{
                ContentType = "html"
                Content = $EmailBody
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = $User.Mail
                    }
                }
            )

 
        }
    }
    # Send the email using Microsoft Graph
    #Send-MgUserMail -UserId $User.Mail -BodyParameter $MailParams
Send-MgUserMail -UserId $SenderID -BodyParameter $MailParams
    }
}

