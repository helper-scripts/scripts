#You must be an admin global. 

##################################
############Variables#############
################################## 
$spnone = "DevopsSPNRBAC001" #<=== important to change
$spntwo = "DevopsSPNRBAC002" #<=== important to change
$Role1 = "Owner"
$Role2 = "Contributor"
$kvsecretname01 = "SPNaccessowner" #<=== important to change
$kvsecretname02 = "SPNaccesscontributor"
$subid  = 'dad6acbd-db2f-4752-b866-2a6de9bfa9d6'
$kvName = 'forrbacdemokv'    #<=========================================== verify the Access Policy before you use this KV
$subscriptionId = (Get-AzContext).Subscription.Id
##################################
############FIN Variables#########
################################## 

connect-AzAccount
Set-AzContext -Subscription $subid

##################################
#########SPN With OWNER RBAC######
##################################  

$sp = New-AzADServicePrincipal -DisplayName $spnone
$clientsec = [System.Net.NetworkCredential]::new("", $sp.Secret).Password
$tenantID = (get-aztenant).Id
$jsonresp = 
@{client_id=$sp.ApplicationId 
    client_secret=$clientsec
    tenant_id=$tenantID}
$jsonresp | ConvertTo-Json

#Store Pass1 in the key vault
$passwordCredential1 = $sp.PasswordCredentials.SecretText
$securespnPassword1 = ConvertTo-SecureString -String $passwordCredential1 -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $kvName -Name $kvsecretname01 -SecretValue $securespnPassword1

#Set the role Owner  

New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $Role1 -Scope  "/subscriptions/$subscriptionId"

##################################
####SPN With Contiributor RBAC####
##################################  

$spp = New-AzADServicePrincipal -DisplayName $spntwo
$clientsec = [System.Net.NetworkCredential]::new("", $spp.Secret).Password
$tenantID = (get-aztenant).Id
$jsonresp = 
@{client_id=$spp.ApplicationId 
    client_secret=$clientsec
    tenant_id=$tenantID}
$jsonresp | ConvertTo-Json

#Store Pass2 in the key vault
$passwordCredential2 = $spp.PasswordCredentials.SecretText
$securespnPassword2 = ConvertTo-SecureString -String $passwordCredential2 -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $kvName -Name $kvsecretname02 -SecretValue $securespnPassword2

#Set the role Contributor

New-AzRoleAssignment -ObjectId $spp.Id -RoleDefinitionName $Role2 -Scope  "/subscriptions/$subscriptionId"