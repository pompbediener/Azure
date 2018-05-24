<#
.SYNOPSIS
    Export NGS with Rulesets & Resource groups
.DESCRIPTION
    Version 0.1 for an export of all NGS's with their rulesets and corresponding Resource groups
.NOTES
    -----------------------------------------------------------------------------------------------------------------------------------
    Function name : Get_Subnets.ps1
    Authors       : Jeroen Nijssen
    Version       : 1.0
    dependancies  : AzureRm - Check in Script
    -----------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------
    Version Changes:
    Date: (dd-MM-YYYY)    Version:     Changed By:           Info:
    15-05-2018            V0.1         xxxxxx                Initial script
    24-05-2018            V1.0         Jeroen Nijssen        Finished script
    -----------------------------------------------------------------------------------------------------------------------------------
#>

##########################
#     Variables         #
##########################

#region Variables
$TenantID = ""
$PathtoFolder = 'C:\Temp\'
$date = Get-Date -UFormat "%Y-%m-%d"
#endregion Variables

##########################
#   Check need modules   #
##########################
 
if( !(Get-Module -ListAvailable -Name Azure) )
{
  Write-Host "Module AzureRm does not exist, installing." -ForegroundColor Yellow
  Install-Module AzureRm 
}  

Else {
Write-Host "Modules are installed" -ForegroundColor Green
}

##########################
#     Login to Azure     #
##########################

#region login
# Login to AzureRM account
$OutputNull=Connect-AzureRMaccount -Tenant $TenantID -Erroraction SilentlyContinue
#endregion Login


##########################
#     Getting Info       #
##########################
#region Getting Subs in Tenant
$Subscription_Name = Get-AzurermSubscription | where {$_.TenantId -eq $TenantID} | Select Name,Id
#endregion

#############################################
#     Looping to subs and getting RsGroups  #
#############################################
#region Looping to Subs and getting the Resourcegroup and Subnets assoisiated to that Sub
Foreach ($Sub_Name in $Subscription_Name)
{ 
    $SelectedSubscription = Set-AzureRmContext -Subscription $Sub_Name.Id
    Write-Host "Searching for Resourcegroups in "$Sub_Name.Name -Foregroundcolor Yellow
    Write-Host "Getting Resourcegroups..." -Foregroundcolor Yellow
        
     $Resources = Get-AzureRMResourceGroup | Select ResourceGroupName
    
Foreach ($Resourcegroupname in $Resources) { 
            $Subnets = Get-AzureRmVirtualNetwork -ResourceGroupName $Resourcegroupname.ResourceGroupName | Get-AzureRmVirtualNetworkSubnetConfig 
            #$Subnets = Get-AzurermVirtualNetworkSubnetConfig -VirtualNetwork (Get-AzureRmVirtualNetwork -ResourceGroupName $Resourcegroupname.ResourceGroupName) 
    if ($Subnets -eq $null){
        Write-host "No Subnets in "$Resourcegroupname.ResourceGroupName -Foregroundcolor Red
        $temp = $Resourcegroupname.ResourceGroupName
        Out-File -FilePath "$PathtoFolder\NOexportSubnets-$SUB_NAME_File-$date.csv" -InputObject "No Subnets are located in $Temp" -Append -Encoding string
    } 
    Else{
    $Array2 = @()
    Write-host "Found Subnets in "$Resourcegroupname.ResourceGroupName -Foregroundcolor Yellow
        ForEach($Subnet in $Subnets){
   
            $objreturn1 = "" | Select Resourcegroupname,SubnetName,AddressPrefix,NetworkSecurityGroup,RouteTable,ServiceEndpoints
            $objreturn1.Resourcegroupname = $Resourcegroupname.ResourceGroupName
            $objreturn1.SubnetName = $Subnet.Name
            $objreturn1.AddressPrefix = $Subnet.AddressPrefix
            $objreturn1.NetworkSecurityGroup = $Subnet.NetworkSecurityGroup.Id
            $objreturn1.RouteTable = $Subnet.RouteTable
            $objreturn1.ServiceEndpoints = $Subnet.ServiceEndpoints
            
            $Array2 += $objreturn1

            $SUB_NAME_File = $Sub_Name.Name
            $Array2 | Export-Csv -Path "$PathtoFolder\exportSubnets-$SUB_NAME_File-$date.csv" -Delimiter ";" -Append -NoTypeInformation 
            Write-Host "Added info to $PathtoFolder\exportSubnets-$SUB_NAME_File-$date.csv" -ForegroundColor Green
            }
            }
            }


  
    
       
}

Write-Host "All done, please check $PathtoFolder" -ForegroundColor Green
#endregion