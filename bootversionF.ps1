########################################################################################################################################################################
############################################################## NOMBRE DE VM (AGENT DEVOPS) A CREER #####################################################################
########################################################################################################################################################################

# Définir le nombre de VM(s) à déployer (Choix Linux ou Windows)
param (
    [Parameter(Mandatory)][int]$nbreVmWindows,
    [Parameter(Mandatory)][int]$nbreVmLinux
)

# Désactiver les messages d'avertissement.
# Documentation : https://docs.microsoft.com/en-us/powershell/azure/faq?view=azps-7.2.0
Set-Item -path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value "true"

########################################################################################################################################################################
############################################################################ PARAMETRES ################################################################################
########################################################################################################################################################################

# Variables d'environnement nécessaires à la configuration de l'Agent Azure DevOps dans chaque VM
$URL                                                               = 'https://dev.azure.com/allymeer-hossen'                                                               #<=== ici l'URL liée à l'Environnement Azure DevOps
$PAT                                                               = 'pwpb7blhk4skkj6tjbvhujoxfikmv5zx2c2yegn7mwxgtdvn6hia'                                                #<=== ici Le Personal Access Token Azure DevOps
$POOL                                                              = 'test'                                                                                                #<=== ici le Pool d'Agent Azure DevOps correspondant
                                                                                                                                                                           #<=== ici l'ID de l'abonnement Azure lié

# Variables d'environnement Azure
$subid                                                             = 'dad6acbd-db2f-4752-b866-2a6de9bfa9d6'                                                               #<=== ici l'ID de l'abonnement Azure lié
$location                                                          = "CanadaCentral"                                                                                       #<=== ici la Région Azure correspondante (par ex : Canada Central)
$rgName                                                            = "rg-caceagt"+ (Get-Random -Maximum 99)                                                          #<=== ici le nom du Groupe de Ressources Azure
$AdminUsername                                                     = "azureuser"                                                                                           #<=== ici le compte utilisé pour l'accès aux VMs Azure 
$tags = @{                                                                                                                                                                 #<=== ici le tag d'environnement (Production / Recette)
    Environnement                                                  = "ProductionDevops"
}

# Réseau
$vnetName                                                          = 'VNetcac'+ (Get-Random -Maximum 99)                                                          #<=== ici le nom du VNET Azure
$subnetName                                                        = 'Subnetcac'+ (Get-Random -Maximum 99)                                                          #<=== ici le nom du Sous-Réseau Azure
$vNetAddressPrefix                                                 = '10.1.0.0/16'                                                                                         #<=== ici le plan d'addressage du VNET Azure
$subnetAdressePrefix                                               = '10.1.0.0/24'                                                                                         #<=== ici le plan d'addressage du Sous-Réseau Azure

# Groupe de sécurité réseau (NSG)
$nsgName                                                           = 'NSGcac'+ (Get-Random -Maximum 99)                                                         #<=== ici le nom du groupes de sécurité réseau
$nsgRule1Name                                                      = 'Devops_Rule'                                                                                         #<=== ici le nom de la règle lié à sécurisation réseau Azure DevOps
$nsgRule1Description                                               = 'Allow Outbound to DEVOPS'                                                                            #<=== ici la description de la règle créée à la ligne précédente
$nsgRule1Access                                                    = 'Allow'                                                                                               #<=== ici l'autorisation ou l'interdiction du trafic réseau
$nsgRule1Protocol                                                  = 'Tcp'                                                                                                 #<=== ici le protocole réseau auquel s'applique une configuration de règle
$nsgRule1Direction                                                 = 'Outbound'                                                                                            #<=== ici la nature du trafic réseau évaluée (entrant ou sortant)
$nsgRule1Priority                                                  = '100'                                                                                                 #<=== ici la priorité d'une régle NSG
$nsgRule1SourceAddressPrefix                                       = 'VirtualNetwork'                                                                                      #<=== ici le segment réseau source
$nsgRule1SourcePortRange                                           = '*'                                                                                                   #<=== ici le port source ou une plage réseau
$nsgRule1DestinationAddressPrefix                                  = 'AzureDevOps'                                                                                         #<=== ici le segment réseau destination
$nsgRule1DestinationPortRange                                      = '443'                                                                                                 #<=== ici le port destination ou une plage réseau

# Passerelle NAT
$publicIPName                                                      = 'PublicIPcac'+ (Get-Random -Maximum 99)                                                          #<=== ici le nom de l'IP Publique liée au composant NAT Gateway
$skuPublicIP                                                       = 'Standard'                                                                                            #<=== ici le type d'IP Publique liée au composant NAT Gateway
$publicIpAllocationMethod                                          = 'Static'                                                                                              #<=== ici la classe d'allocation de l'IP Publique (statique ou dynamique)
$natGatewayName                                                    = 'myNATgatewayca'+ (Get-Random -Maximum 99)                                                          #<=== ici le nom du composant NAT Gateway
$skuNatGateway                                                     = 'Standard'                                                                                            #<=== ici le type de composant NAT Gateway
$natGatewayIdleTimeoutInMinutes                                    = '10'                                                                                                  #<=== ici le délai d'inactivité du composant NAT Gateway

# Key Vault
$kvName                                                            = "kv-prodca"+ (Get-Random -Maximum 99)                                                         #<=== ici le nom du composant Key Vault 
$kvsecretname01                                                    = "SPNforRbacowner1"                                                                                    #<=== ici le secret du SPN Owner 
$kvsecretname02                                                    = "SPNforRbaccontributor1"                                                                              #<=== ici le secret du SPN Owner 
																																																													   
# Variables VM Linux et Windows
$nicWinNamePrefix                                                  = 'WinNicac'+ (Get-Random -Maximum 99)                                                          #<=== ici le préfixe du nom de la carte réseau associée au(x) VM(s) Windows
$nicLinNamePrefix                                                  = 'myLinNicac'+ (Get-Random -Maximum 99)                                                          #<=== ici le préfixe du nom de la carte réseau associée au(x) VM(s) Linux
$vmWinNamePrefix                                                   = 'vm-windows'+ (Get-Random -Maximum 99)                                                          #<=== ici le préfixe du nom de la VM Windows
$vmLinNamePrefix                                                   = 'vm-linux'+ (Get-Random -Maximum 99)                                                          #<=== ici le préfixe du nom de la VM Windows
$vmSize                                                            = 'Standard_D2S_V3'                                                                                     #<=== ici la taille de la VM (Windows ou Linux)
$vmLinOsPublisherName                                              = 'Canonical'                                                                                           #<=== ici l'image pour linux
$vmLinOsOffer                                                      = 'UbuntuServer'                                                                                        #<=== ici la distribution Linux retenue
$vmLinOsVersion                                                    = 'latest'                                                                                              #<=== ici la version de la distribution Linux retenue
$vmLinOsSkus                                                       = '18.04-LTS'                                                                                           #<=== ici le type d'instance de la VM Windows
$vmWinOsPublisherName                                              = 'MicrosoftWindowsServer'                                                                              #<=== ici l'image pour Windows
$vmWinOsOffer                                                      = 'WindowsServer'                                                                                       #<=== ici l'OS Windows retenu
$vmWinOsVersion                                                    = 'latest'                                                                                              #<=== ici la version de l'OS Windows retenu
$vmWinOsSkus                                                       = '2019-Datacenter'                                                                                     #<=== ici le type d'instance pour windows
$vmDiskStorageAccountType                                          = 'Premium_LRS'                                                                                         #<=== ici le type de disque 
$vmDiskCreateOption                                                = 'FromImage'                                                                                           #<=== ici l'option de la création du disque

# Log Analytics Workspace
$lawName                                                           = 'mylaw16cace'+ (Get-Random -Maximum 99)                                                         #<=== ici le nom du composant Log Analytics Workspace
$lawSku                                                            = 'pergb2018'                                                                                           #<=== ici le niveau tarifaire du composant Log Analytics Workspace

# Backend Terraform
$rgNamebackend                                                     = "rg-terraformbkt"+ (Get-Random -Maximum 99)                                                                #<=== ici le nom du Groupe de Ressources Azure
$StorageAccountName                                                = "saterraformbkt"+ (Get-Random -Maximum 99)                                                                 #<=== ici le nom du compte de stockage Azure utilisé pour Terraform 

# Principal de Service (SPN)
$spnowner                                                          = "DevopsSPNRBACowner"                                                                                  #<=== ici le nom du Principal de Service avec le Rôle Owner                                       
$spncontributor                                                    = "DevopsSPNRBACcontrib"                                                                                #<=== ici le nom du Principal de Service avec le Rôle Contributeur 
$Roleowner                                                         = "Owner"                                                                                               #<=== ici le Rôle assigné au 1er SPN
$Rolecontrib                                                       = "Contributor"                                                                                         #<=== ici le Rôle assigné au 2nd SPN

# Nom d'extension personnalisé pour VM Linux ou Windows
$namecustsc                                                        = 'CustomScriptAgent'                                                                                   #<=== ici le nom de l'extension personnalisée
$AgentdevopsWind                                                   = "https://raw.githubusercontent.com/GithubVictrix/Victrix/main/AgentWindows1.ps1"                      #<=== ici le Lien du fichier github d'installation de l'Agent DevOps sur VM Windows
$Windowstools                                                      = "https://raw.githubusercontent.com/mohameedtrabelsi/mohameedtrabelsi/main/toolswindows.ps1"           #<=== ici le Lien du fichier github d'installation de Terraform,AZ CLI,module Az,Git,Bicep sur VM Windows
$linuxtools                                                        = "https://raw.githubusercontent.com/mbouaklaine/MohamedBouaklaine/main/linuxtools.sh"           #<=== ici le Lien du fichier github d'installation de Terraform,AZ CLI,module Az,Git,Bicep sur VM Linux
# Compteur zéro pour le nombre de VM
$i                                                                 = 0

########################################################################################################################################################################
####################################################################### FIN SECTION PARAMETRES #########################################################################
########################################################################################################################################################################

# Connexion à l'environnement Azure
Connect-AzAccount | Out-Null 
Write-Host "Vous êtes connectés à l'abonnement Azure"
Set-AzContext -Subscription $subid | Out-Null  

########################################################################################################################################################################
####################################################################### FONCTIONS ######################################################################################
########################################################################################################################################################################

# Fonction pour créer les VMs Linux
function CreateLinVm {
# Créer une configuration de machine virtuelle
# Créer l'interface réseau    
    $nic_param = @{
        Name              = $nicLinNamePrefix + $i
        ResourceGroupName = $rgName
        Location          = $location
        SubnetId          = $vnet.Subnets[0].Id
        Tag               = $tags
    }
    $nic = New-AzNetworkInterface @nic_param

# Nom et Taille de la VM Linux
    $vmSzParams = @{
        VmName  = $vmLinNamePrefix + $i
        VMSize  = $vmSize
    }
# Infos VM, Compte d'Accès et désactivation de l'authentification par mot de passe pour Linux
    $VmOsParams = @{
        Linux                         = $true
        ComputerName                  = $vmLinNamePrefix + $i
        Credential                    = $cred
        DisablePasswordAuthentication = $true
    }
 # Infos OS VM Linux
    $vmImageParams = @{
        PublisherName = $vmLinOsPublisherName
        Offer         = $vmLinOsOffer
        Version       = $vmLinOsVersion
        Skus          = $vmLinOsSkus
    }
# Infos Disque OS / Options de création
    $vmDiskOsParams = @{
        StorageAccountType = $vmDiskStorageAccountType
        CreateOption       = $vmDiskCreateOption
    }
# Désactivation du Boot Diagnostic
    $vmBootDiagnosticParams = @{
        Disable 			= $true
    }
# Paramètrage de la VM 
    $vmConfig = New-AzVMConfig @vmSzParams `
    | Set-AzVMOperatingSystem @VmOsParams `
    | Set-AzVMSourceImage @vmImageParams `
    | Set-AzVMOSDisk @vmDiskOsParams `
    | Set-AzVMBootDiagnostic @vmBootDiagnosticParams `
    | Add-AzVMNetworkInterface -Id $nic.Id `
    | Add-AzVMSshPublicKey -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"
 # Création de la VM
    New-AzVM `
        -ResourceGroupName $rgName `
        -Location $location `
        -VM $vmConfig `
        -Tag $tags

}
# Création VM Windows avec la fonction CreateWindowsVm
function CreateWindowsVm {
# Fonction pour créer le ou les VM(s) Windows
# Créer l'interface réseau
    $nic_param = @{
        Name              = $nicWinNamePrefix + $i
        ResourceGroupName = $rgName
        Location          = $location
        SubnetId          = $vnet.Subnets[0].Id
        Tag               = $tags
    }
    $nic = New-AzNetworkInterface @nic_param

# Nom de la VM et la taille
    $vmSzParams = @{
        VmName  = $vmWinNamePrefix + $i
        VMSize  = $vmSize
    }
# Infos VM, Compte d'Accès
    $VmOsParams = @{
        Windows      = $true
        ComputerName = $vmWinNamePrefix + $i
        Credential   = $wincred
    }
 # Infos OS VM Windows
    $vmImageParams = @{
        PublisherName = $vmWinOsPublisherName
        Offer         = $vmWinOsOffer
        Version       = $vmWinOsVersion
        Skus          = $vmWinOsSkus
    }
# Infos Disque OS / Option de création
    $vmDiskOsParams = @{
        StorageAccountType = $vmDiskStorageAccountType
        CreateOption       = $vmDiskCreateOption
    }
# Désactivation du Boot Diagnostic
    $vmBootDiagnosticParams = @{
        Disable = $true
    }
# Paramètrage de la VM
    $vmConfig = New-AzVMConfig @vmSzParams `
    | Set-AzVMOperatingSystem @VmOsParams `
    | Set-AzVMSourceImage @vmImageParams `
    | Set-AzVMOSDisk @vmDiskOsParams `
    | Set-AzVMBootDiagnostic @vmBootDiagnosticParams `
    | Add-AzVMNetworkInterface -Id $nic.Id
# Création de la VM
    New-AzVM `
        -ResourceGroupName $rgName `
        -Location $location `
        -VM $vmConfig `
        -Tag $tags
}
# Fonction pour générer un mot de passe aléatoire pour la machine virtuelle
function GeneratePassword {
    function Get-RandomCharacters($length, $characters) {
        $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
        $private:ofs = ""
        return [String]$characters[$random]
    }
    
    function Scramble-String([string]$inputString) {     
        $characterArray = $inputString.ToCharArray()   
        $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
        $outputString = -join $scrambledStringArray
        return $outputString 
    }
    
    $password  = Get-RandomCharacters -length 6 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 2 -characters '1234567890'
    $password += Get-RandomCharacters -length 2 -characters '!"§$%&/()=?}][{@#*+'
    
    $password = Scramble-String -inputString $password
    
    return $password
}
# Fonction pour vérifier si les noms des ressources existent déjà avant exécution du processus de création
function checkExistingResource {
    param (
        [string]$resource
    )

    switch ($resource) {
        RG { 
            If (Get-AzResourceGroup -name $rgname -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le Groupe de Ressources existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        RGBE { 
            If (Get-AzResourceGroup -name $rgNameBackend -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le Groupe de Ressources lié au Backend Terraform existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        SABE { 
            If (Get-AzResourceGroup -name  $StorageAccountName -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le compte de stockage lié au Backend Terraform existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        KV {
            If (Get-AzKeyVault -Vaultname $kvName -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le Key Vault existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
            If (Get-AzKeyVault -Vaultname $kvName -Location $location -InRemovedState -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le Key Vault existe déjà. Il est en mode soft-delete. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        PublicIP { 
            If (Get-AzPublicIpAddress -name $publicIPName -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "L'IP Publique existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        NatGateway { 
            $allRgs = Get-AzResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue
            foreach ($allRg in $allRgs) {
                If (Get-AzNatGateway -name $natGatewayName -ResourceGroupName $allRg -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                    Write-Host "Le composant NAT Gateway existe déjà. Changer le nom" -ForegroundColor Red
                    Exit
                }
            }
        }

        NSG { 
            If (Get-AzNetworkSecurityGroup -name $nsgName -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le NSG existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        Vnet { 
            If (Get-AzVirtualNetwork -name $vnetName -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                Write-Host "Le VNET existe déjà. Changer le nom" -ForegroundColor Red
                Exit
            }
        }

        VM { 
            if ($nbreVmWindows -gt 0) {
                $vmWinNameCheck = $vmWinNamePrefix + '1'
                If (Get-AzVm -name $vmWinNameCheck -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                    Write-Host "La VM Windows existe déjà. Changer le nom" -ForegroundColor Red
                    Exit
                }
            }

            if ($nbreVmLinux -gt 0) {
                $vmLinNameCheck = $vmLinNamePrefix + '1'
                If (Get-AzVm -name $vmLinNameCheck -ErrorVariable notPresent -ErrorAction SilentlyContinue) {
                    Write-Host "La VM Linux existe déjà. Changer le nom" -ForegroundColor Red
                    Exit
                }
            }
        }

        

        Default {}
    }
    
}

#  Vérification de l'existance des ressources Azure
checkExistingResource -resource "RG"
checkExistingResource -resource "RGBE"
checkExistingResource -resource "SABE"
checkExistingResource -resource "KV"
checkExistingResource -resource "PublicIP"
checkExistingResource -resource "NatGateway"
checkExistingResource -resource "NSG"
checkExistingResource -resource "Vnet"
checkExistingResource -resource "VM"

########################################################################################################################################################################
####################################################################### FIN SECTION FONCTIONS ##########################################################################
########################################################################################################################################################################

########################################################################################################################################################################
####################################################################### CREATION DES RESSOURCES ########################################################################
########################################################################################################################################################################

try {
# Création d'un Groupe de Ressources 
    $rg_param = @{
        Name     = $rgName
        Location = $location
        Tag      = $tags
    }
    New-AzResourceGroup @rg_param | Out-Null
    Write-Host "Création du Groupe de Ressources [$rgName]"
# Création d'un Groupe de Ressources lié au backend Terraform
    $rgbe_param = @{
        Name     = $rgNameBackend
        Location = $location
        Tag      = $tags
    }
    New-AzResourceGroup @rgbe_param | Out-Null
    Write-Host "Création du Groupe de Ressources lié au backend terraform [$rgNameBackend]"
# Création d'un Key Vault
    $kv_param = @{
        Name              = $kvName
        ResourceGroupName = $rgName
        Location          = $location
    }
    New-AzKeyVault @kv_param -EnabledForDiskEncryption | Out-Null

    $KeyVault = Get-AzKeyVault -VaultName $kvName -ResourceGroupName $rgName
    Write-Host "Création du Key Vault [$kvName]"

# Configuration de l'authentification SSH 
# Vérification de chemin pour les clés publiques et privées
    $directoryPath = 'C:\temp\ssh'
    if (!(Test-Path $directoryPath)) {
        New-item -Path $directoryPath -ItemType Directory
    }

    $privateKeyPath = $directoryPath + '/id_rsa_devops'
    $publicKeyPath = $directoryPath + '/id_rsa_devops.pub'

# Création Paire de Clés SSH
    ssh-keygen -m PEM -t rsa -b 4096 -f $privateKeyPath -N '""' | Out-Null
    Write-Host "Création Clés SSH OK"

# Configuration Clés SSH
    $sshPublicKey  = cat $publicKeyPath
    $sshPrivateKey = $privateKeyPath
    Write-Host "Configuration Clés SSH OK"

# Stockage de la clé SSH dans le Key Vault
    $Secret = (ConvertTo-SecureString (Get-Content $sshPrivateKey -Raw) -force -AsPlainText)
    Set-AzKeyVaultSecret -VaultName $kvName -Name "SSHPrivateKey" -SecretValue $Secret >$null 2>&1
    Write-Host "Clés SSH stockée dans le Key Vault"

 # Création d'une adresse IP publique pour la passerelle NAT
    $PublicIP_param = @{
        Name              = $publicIPName
        ResourceGroupName = $rgName
        Location          = $location
        Sku               = $skuPublicIP
        AllocationMethod  = $publicIpAllocationMethod
        Tag               = $tags
    }
    $PublicIP = New-AzPublicIpAddress @PublicIP_param
    $CurrentIppub = (Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $publicIPName).IpAddress
    Write-Host "Adresse IP publique affectée au composant NAT Gateway :"$CurrentIppub""

 # Création d'une passerelle NAT
    $natGateway_param = @{
        ResourceGroupName    = $rgName
        Name                 = $natGatewayName
        IdleTimeoutInMinutes = $natGatewayIdleTimeoutInMinutes
        Sku                  = $skuNatGateway
        Location             = $location
        PublicIpAddress      = $PublicIP
        Tag                  = $tags
    }
    $natGateway = New-AzNatGateway @natGateway_param
    Write-Host "Le service NAT Gateway [$natGatewayName] est créé"
# Création du NSG avec la règle d'autorisation pour le service Azure Devops

    $nsgRule1_Param = @{
        Name                     = $nsgRule1Name
        Description              = $nsgRule1Description
        Access                   = $nsgRule1Access
        Protocol                 = $nsgRule1Protocol
        Direction                = $nsgRule1Direction
        Priority                 = $nsgRule1Priority
        SourceAddressPrefix      = $nsgRule1SourceAddressPrefix
        SourcePortRange          = $nsgRule1SourcePortRange
        DestinationAddressPrefix = $nsgRule1DestinationAddressPrefix
        DestinationPortRange     = $nsgRule1DestinationPortRange
    }
    $nsgRule1 = New-AzNetworkSecurityRuleConfig @nsgRule1_Param
    Write-Host "La régle autorisant l'accès à Azure DevOps est bien ajoutée au NSG"

# Création du NSG 
    $nsg_param = @{
        Name              = $nsgName
        ResourceGroupName = $rgName
        Location          = $location
        SecurityRules     = $nsgRule1
        Tag               = $tags         
    }
    $nsg = New-AzNetworkSecurityGroup @nsg_param
    Write-Host "Le Groupe de Sécurité Réseau [$nsgName] est créé"  
    
# Création + Configuration du sous-réseau / Association du Subnet à la passerelle NAT ainsi qu'au NSG
    $subnetConfig_param = @{
        Name                 = $subnetName
        AddressPrefix        = $subnetAdressePrefix
        NatGateway           = $natGateway
        NetworkSecurityGroup = $nsg
    }
    $subnetConfig = New-AzVirtualNetworkSubnetConfig @subnetConfig_param 

# Création d'un réseau virtuel (VNET)
    $vnet_param = @{
        Name              = $vnetName
        ResourceGroupName = $rgName
        Location          = $location
        AddressPrefix     = $vNetAddressPrefix
        Subnet            = $subnetConfig
        Tag               = $tags
    }   
    $vnet = New-AzVirtualNetwork @vnet_param
    $vnetAddprefix = (Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName).AddressSpace.AddressPrefixes
    Write-Host "Création du VNET [$vnetName] avec le plan d'adressage :"$vnetAddprefix"" 
    $subnetAddprefix = (Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).AddressPrefix
    Write-Host "Création du Subnet [$subnetName] avec le plan d'adressage :"$subnetAddprefix""

# Création d'un Log Analytics
    $law_params = @{
        Name              = $lawName
        ResourceGroupName = $rgName
        Location          = $location
        Sku               = $lawSku
    }
    $lawConfig = New-AzOperationalInsightsWorkspace @law_params
    Write-Host "Création du Log Analytics Workspace [$lawName]"

# Création d'un compte de stockage pour le backend Terraform
    $sa_param = @{
        Name              = $StorageAccountName
        ResourceGroupName = $rgNameBackend
        Location          = $location
        SkuName           = $skuName
    }
   ## Créer Storage Account pour le backend Terraform
New-AzStorageAccount -ResourceGroupName $rgNamebackend -AccountName $StorageAccountName -Location $location -SkuName Standard_GRS -Kind StorageV2 -Tag $tags | Out-Null

########################################################################################################################################################################
####################################################################### FIN SECTION CREATION DES RESSOURCES ############################################################
########################################################################################################################################################################

########################################################################################################################################################################
####################################################################### CREATION DES VM ################################################################################
########################################################################################################################################################################

# Création VMs Linux

    if ($nbreVmLinux -gt 0 ) {
        
# Définir un objet d'identification et le stocker dans le KEY VAULT
        $securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($AdminUsername, $securePassword)
        
        do {
            
            $i++
            CreateLinVm         
            
        } until ($i -eq $nbreVmLinux)
    }

# Création VMs Windows
    if ($nbreVmWindows -gt 0 ) {
        
        $i = 0
# Définir un objet d'identification et le stocker dans le KEY VAULT
        $pass = GeneratePassword
        $secureWinPassword = ConvertTo-SecureString $pass -AsPlainText -Force
        
        Set-AzKeyVaultSecret -VaultName $kvName -Name "AzureUserPassword" -SecretValue $secureWinPassword >$null 2>&1
        
        $wincred = New-Object System.Management.Automation.PSCredential ($AdminUsername, $secureWinPassword)
        
        do {
# Création VM Windows avec la fonction CreateWindowsVm
            $i++
            CreateWindowsVm         
            
        } until ($i -eq $nbreVmWindows)
    }

    Remove-Item -Path $directoryPath -Recurse -Force


########################################################################################################################################################################
####################################################################### FIN SECTION CREATION DES VM ####################################################################
#######################################################################################################################################################################

########################################################################################################################################################################
####################################################################### Activation Event & Logs ######################################################################
########################################################################################################################################################################

# Log Analytics Worskpace Configuration
$workspace         = $lawConfig
$workspaceId       = $workspace.CustomerId
$workspaceKey      = Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $rgName -Name $workspace.Name
$Publicsettings1   = @{"workspaceId" = $workspaceId }
$Protectedsettings = @{"workspaceKey" = $workspaceKey.primarysharedkey }
$DiagnosticSettingName = 'Envoi Logs Workspace Log Analytics'


# Activer la collecte de journaux IIS à l'aide d'un agent
Enable-AzOperationalInsightsIISLogCollection -ResourceGroupName $rgName -WorkspaceName $workspace.Name | Out-Null

## Activation Compteurs Performance Linux
New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -ObjectName "Logical Disk" -InstanceName "*"  -CounterNames @("% Used Inodes", "Free Megabytes", "Disk Transfers/sec", "Disk Reads/sec", "Disk Writes/sec", "% Free Space" ) -IntervalSeconds 60  -Name "Linux Disk Performance Counters" -Force | Out-Null
New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -ObjectName "Processor" -InstanceName "*"  -CounterNames "% Processor Time" -IntervalSeconds 60  -Name "Processor Time" -Force  | Out-Null
New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -ObjectName "Memory" -InstanceName "*"  -CounterNames "% Available Memory" -IntervalSeconds 60  -Name "Percent Available Memory" -Force | Out-Null
New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -ObjectName "System" -InstanceName "*"  -CounterNames "Uptime" -IntervalSeconds 3600  -Name "uptime" -Force | Out-Null
Enable-AzOperationalInsightsLinuxPerformanceCollection -ResourceGroupName $rgName -WorkspaceName $workspace.Name | Out-Null

# Activation Collecte Syslog Linux
New-AzOperationalInsightsLinuxSyslogDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -Facility "kern" -CollectEmergency -CollectAlert -CollectCritical -CollectError -CollectWarning -Name "kernel syslog collection" -force | Out-Null
New-AzOperationalInsightsLinuxSyslogDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -Facility "auth" -CollectEmergency -CollectAlert -CollectCritical -CollectError -CollectWarning -Name "auth syslog collection" -Force | Out-Null
New-AzOperationalInsightsLinuxSyslogDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -Facility "daemon" -CollectEmergency -CollectAlert -CollectCritical -CollectError -CollectWarning -Name "daemon syslog collection" -Force | Out-Null
New-AzOperationalInsightsLinuxSyslogDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -Facility "syslog" -CollectEmergency -CollectAlert -CollectCritical -CollectError -CollectWarning -Name "syslog syslog collection" -Force | Out-Null
Enable-AzOperationalInsightsLinuxSyslogCollection -ResourceGroupName $rgName -WorkspaceName $workspace.Name | Out-Null

# Activation des collections d'événements Windows
New-AzOperationalInsightsWindowsEventDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -EventLogName "Application" -CollectErrors -CollectWarnings -Name "Application Event Log" -force | Out-Null
New-AzOperationalInsightsWindowsEventDataSource -ResourceGroupName $rgName -WorkspaceName $workspace.Name -EventLogName "System" -CollectErrors -CollectWarnings -Name "System Event Log"  -force | Out-Null

#  Ajout des compteurs de performances Windows à l'espace de travail
$perfCounters = 'LogicalDisk(*)\% Free Space',
'LogicalDisk(*)\Disk Reads/sec',
'LogicalDisk(*)\Disk Transfers/sec',
'LogicalDisk(*)\Disk Writes/sec',
'LogicalDisk(*)\Free Megabytes',
'Processor(_Total)\% Processor Time',
'Network Adapter(*)\Bytes Received/sec',
'Network Adapter(*)\Bytes Sent/sec'
foreach ($perfCounter in $perfCounters) {
    $perfArray = $perfCounter.split("\").split("(").split(")")
    $objectName = $perfArray[0]
    $instanceName = $perfArray[1]
    $counterName = $perfArray[3]
    $name = ("$objectName-$counterName") -replace "/", "Per" -replace "%", "Percent" 
    New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ErrorAction Continue -ResourceGroupName $rgName `
            -WorkspaceName $workspace.Name -ObjectName $objectName -InstanceName $instanceName -CounterName $counterName `
            -IntervalSeconds 60  -Name $name -Force | Out-Null
}

# Mise à niveau vers une nouvelle solution pour Azure Monitor pour les machines virtuelles
Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgName  -WorkspaceName $workspace.Name -IntelligencePackName "VMInsights" -Enabled $True | Out-Null

# Configurer le journal d'activité sur l'abonnement pour transférer tous les événements vers le Workspace Log Analytics
$list = @()
Get-AzSubscriptionDiagnosticSettingCategory | ForEach-Object {
$list += (New-AzDiagnosticDetailSetting -Log -Category $_.Name -Enabled)
}
$setting =New-AzDiagnosticSetting -Name $DiagnosticSettingName -SubscriptionId $subid -WorkspaceId $Workspace.resourceid -Setting $list 
Set-AzDiagnosticSetting -InputObject $setting  | Out-Null

########################################################################################################################################################################
############################ CHIFFREMENT DISQUES & EXTENSIONS PERSONNALISEES  VM LINUX #######################################################
########################################################################################################################################################################
# LINUX
# Chiffrement Disques VM avec le Key Vault /!\ Debian non supportée par le solution de chiffrement préconisée
    if ($nbreVmLinux -gt 0 ) {
        $linuxVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Linux' }

        foreach ($linuxVM in $linuxVMs) {
            $KeyVault = Get-AzKeyVault -VaultName $kvName -ResourceGroupName $rgName
            Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgName -VMName $linuxVM.Name -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -EncryptFormatAll -SkipVmBackup -VolumeType All -Force    
            Write-Host "Chiffrement des disques réalisé sur $nbreVmLinux VM Linux"

            }
    }
# Installation et Configuration de l'Agent DevOps, Terraform, GIT, Azure CLI et Modules Az Powershell VM Linux
    if ($nbreVmLinux -gt 0 ) {
        $linuxVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Linux' }
     
       foreach ($linuxVM in $linuxVMs) {
            Do {
                # Do stuff
                # Sleep 25 minutes
                Start-Sleep -s 1500
            }
            while ($condition -eq $true)
       $extensionName = "tools_devops"
                  $fileUri = @($linuxtools)
                  $PublicSettings = @{'fileUris' =$fileUri; "commandToExecute" = "./linuxtools.sh $URL $PAT $POOL "};           
                  Set-AzVMExtension -ResourceGroupName $rgName -Location $location -VMName $linuxVM.Name -Name $extensionName -Publisher "Microsoft.Azure.Extensions" -Type "customScript" -TypeHandlerVersion "2.0" -Settings $PublicSettings
                  Write-Host "Agent Devops, Terraform, GIT, AZ CLI, Bicep et modules AZ Pshell configurés sur $nbreVmLinux VM Linux"  
    
         }
     }
# Configuration d'un Log Analytics Worskpace VM Linux
if ($nbreVmLinux -gt 0 ) {
    $linuxVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Linux' }

    foreach ($linuxVM in $linuxVMs) {
        
        Set-AzVMExtension `
            -Name "OmsAgentForLinux" `
            -ResourceGroupName $rgName `
            -VMName $linuxVM.Name `
            -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
            -ExtensionType 'OmsAgentForLinux' `
            -TypeHandlerVersion 1.0 `
            -Settings $PublicSettings1 `
            -ProtectedSettings $ProtectedSettings `
            -Location $Location
            Write-Host "L'agent Log Analytics est bien configuré sur la VM linux"
    }
}
 
#####################################################################################################################################################################
################################### CHIFFREMENT DISQUES & EXTENSIONS PERSONNALISEES  VM Windows  ######################################################################
#####################################################################################################################################################################
# WINDOWS
# Configuration d'un Log Analytics Worskpace VM Windows
    if ($nbreVmWindows -gt 0 ) {
        $WindowsVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Windows' }
    
        foreach ($WindowsVM in $WindowsVMs) {
            
            Set-AzVMExtension `
                -Name "MicrosoftMonitoringAgent" `
                -ResourceGroupName $rgName `
                -VMName $WindowsVM.Name `
                -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                -ExtensionType 'MicrosoftMonitoringAgent' `
                -TypeHandlerVersion 1.0 `
                -Settings $PublicSettings1 `
                -ProtectedSettings $ProtectedSettings `
                -Location $Location

            Write-Host "L'agent Log Analytics est bien configuré sur la VM Windows"
        }
    }
    
# Installation et Configuration Agent DevOps VM Windows
    if ($nbreVmWindows -gt 0 ) {
        $WindowsVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Windows' }
    
        foreach ($WindowsVM in $WindowsVMs) {
             
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgName  -VMName $WindowsVM.Name -Name $namecustsc -FileUri $AgentdevopsWind -Run "AgentWindows1.ps1 -URL $URL -PAT $PAT -POOL $POOL" -Location $location   
            Write-Host "L'agent Azure DevOps est bien configuré sur la VM Windows"
        }
    }
  
# Installation et Configuration Terraform, GIT, AZ CLI, module AZ et Bicep Windows
    if ($nbreVmWindows -gt 0 ) {
        $WindowsVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Windows' }
    
        foreach ($WindowsVM in $WindowsVMs) {
             
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgName  -VMName $WindowsVM.Name -Name $namecustsc -FileUri $Windowstools -Run "toolswindows.ps1" -Location $location   
            Write-Host "Terraform, GIT, AZ CLI, module AZ et Bicep sont configurés sur $nbreVmWindows VM Windows"
        }
    }
 
    # WINDOWS
# Chiffrement Disques VM avec le Key Vault 
if ($nbreVmWindows -gt 0 ) {
    $WindowsVMs = Get-AzVM -ResourceGroupName $rgName | Select-Object -Property Name, @{Name = 'OSType'; Expression = { $_.StorageProfile.OSDisk.OSType } } | Where-Object { $_.OsType -eq 'Windows' }

    foreach ($WindowsVM in $WindowsVMs) {
        
            Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgName -VMName $WindowsVM.Name -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -Force       
            Write-Host "Chiffrement des disques réalisé sur $nbreVmWindows VM Windows"
        }
}

########################################################################################################################################################################
############################################# FIN SECTION CHIFFREMENT DISQUES & EXTENSIONS PERSONNALISEES #######################################################
########################################################################################################################################################################

########################################################################################################################################################################
####################################################################### CREATION PRINCIPAL DE SERVICE ##################################################################
########################################################################################################################################################################

# Création du Principal de Service n°1 avec un rôle de Contributeur
# Création SPN et son secret
	$spp       = New-AzADServicePrincipal -DisplayName $spncontributor
	$clientsec = [System.Net.NetworkCredential]::new("", $spp.Secret).Password
	$tenantID  = (get-aztenant).Id
	$jsonresp  = 
		@{client_id=$spp.ApplicationId 
		client_secret=$clientsec
		tenant_id=$tenantID}
		$jsonresp | ConvertTo-Json | Out-Null
#Write-Host "Création du Principal de Service avec le rôle Contributeur [$spncontributor]"

# Enregistrement des informations d'identification du SPN dans le Key Vault
	$passwordCredential2 = $spp.PasswordCredentials.SecretText
	$securespnPassword2  = ConvertTo-SecureString -String $passwordCredential2 -AsPlainText -Force
	Set-AzKeyVaultSecret -VaultName $kvName -Name $kvsecretname02 -SecretValue $securespnPassword2 >$null 2>&1

# Définir le rôle Contributeur
	New-AzRoleAssignment -ObjectId $spp.Id -RoleDefinitionName $Rolecontrib -Scope "/subscriptions/$subid" | Out-Null

# Création d'un deuxième SPN en assignant le rôle Owner
# Création SPN et son secret
	$spt = New-AzADServicePrincipal -DisplayName $spnowner 
	$clientsec = [System.Net.NetworkCredential]::new("", $spt.Secret).Password
	$tenantID  = (get-aztenant).Id
	$jsonresp  = 
		@{client_id=$spt.ApplicationId 
		client_secret=$clientsec
		tenant_id=$tenantID}
		$jsonresp | ConvertTo-Json | Out-Null
Write-Host "Création du Principal de Service avec le rôle Contributeur [$spnowner]"

# Stocker les informations d'identification SPN dans le KeyVault
	$passwordCredential1 = $spt.PasswordCredentials.SecretText
	$securespnPassword1 = ConvertTo-SecureString -String $passwordCredential1 -AsPlainText -Force
	Set-AzKeyVaultSecret -VaultName $kvName -Name $kvsecretname01 -SecretValue $securespnPassword1 >$null 2>&1

## Définir le rôle Owner
	New-AzRoleAssignment -ObjectId $spt.Id -RoleDefinitionName $Roleowner -Scope  "/subscriptions/$subid" | Out-Null

########################################################################################################################################################################
####################################################################### FIN SECTION CREATION PRINCIPAL DE SERVICE ######################################################
########################################################################################################################################################################

}
catch {
    
    $formatstring = "{0} : {1}`n{2}`n"
    $fields       = $_.InvocationInfo.MyCommand.Name,
    $_.Exception.Message,
    $_.InvocationInfo.PositionMessage

    Write-Host -Foreground Red ($formatstring -f $fields)

    #Write-Host -Foreground Red "*****Delete all resources*****" : don't active the two commands because it will be delete all the resources created before.
    
    #Remove-AzResourceGroup -Name $rgName -Force
    #Remove-Item -Path $directoryPath -Recurse -Force


} 

