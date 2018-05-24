<#
.SYNOPSIS
    Export NGS with Rulesets & Resource groups
.DESCRIPTION
    Version 0.1 for an export of all NGS's with their rulesets and corresponding Resource groups
.NOTES
    -----------------------------------------------------------------------------------------------------------------------------------
    Function name : Get_NSG.ps1
    Authors       : Jeroen Nijssen
    Version       : 1.0
    dependancies  : Azure - Check in Script
    -----------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------
    Version Changes:
    Date: (dd-MM-YYYY)    Version:     Changed By:           Info:
    15-05-2018            V0.1         xxxxx                 Initial script
    24-05-2018            V1.0         Jeroen Nijssen        Finished script
    -----------------------------------------------------------------------------------------------------------------------------------
#>

##########################
#     Variables         #
##########################

#region Variables
$TenantID =
$PathtoFolder = 'C:\Temp\'
$date = Get-Date -UFormat "%Y-%m-%d"
#endregion Variables

##########################
#   Check need modules   #
##########################
 
if( !(Get-Module -ListAvailable -Name Azure) )
{
  Write-Host "Module AzureAD does not exist, installing." -ForegroundColor Yellow
  Install-Module Azure 
}  

Else {
Write-Host "Modules are installed" -ForegroundColor Green
}

##########################
#     Login to Azure     #
##########################

#region login
# Login to AzureRM account
$OutputNull=Add-AzureAccount -Tenant $TenantID -Erroraction SilentlyContinue
#endregion Login


##########################
#     Getting Info       #
##########################
#region Getting Subs in Tenant
$Subscription_Name = Get-AzureSubscription | where {$_.TenantId -eq $TenantID} | Select SubscriptionName
#endregion

#############################################
#     Looping to subs and getting NSGs      #
#############################################
#region Looping to Subs and getting the NSGs assoisiated to that Sub
Foreach ($Sub_Name in $Subscription_Name)
{ 
    $SelectedSubscription = Select-AzureSubscription -SubscriptionName $Sub_Name.SubscriptionName
    #Select-AzureSubscription -SubscriptionName 'PostNL Sogeti-P1'
    #Select-AzureRmSubscription -Subscriptionid $Subid 
    Write-Host "searching Network security groups in "$Sub_Name.SubscriptionName -Foregroundcolor Yellow
    Write-Host "Getting NSG Rules ...." -Foregroundcolor Yellow
        
    Try{$NSGs = Get-AzureNetworkSecurityGroup -ErrorAction Stop}
    Catch{ return "Failed to collect NSGs in subscription"}

    $Array = @()

    ForEach($NSG in $NSGs){
        $NSGName = $NSG.name
        $Rules = Get-AzureNetworkSecurityGroup -Name $NSGName -Detailed | Select-Object -ExpandProperty Rules | Where{!($_.IsDefault)}

        ForEach($Rule in $Rules){
            $objreturn = "" | Select NSGName,RuleName,Type,Priority,Action,SourceAddressPrefix,SourcePortRange,DestinationAddressPrefix,DestinationPortRange,Protocol
            $objreturn.NSGName = $NSGName
            $objreturn.RuleName = $Rule.Name
            $objreturn.Type = $Rule.Type
            $objreturn.Priority = $Rule.Priority
            $objreturn.Action = $Rule.Action
            $objreturn.SourceAddressPrefix = $Rule.SourceAddressPrefix
            $objreturn.SourcePortRange = $Rule.SourcePortRange
            $objreturn.DestinationAddressPrefix = $Rule.DestinationAddressPrefix
            $objreturn.DestinationPortRange = $Rule.DestinationPortRange
            $objreturn.Protocol = $Rule.Protocol

            $Array += $objreturn
        }
    }
    $SUB_NAME_File = $Sub_Name.SubscriptionName
    $Array | Export-Csv -Path "$PathtoFolder\exportNSG-$SUB_NAME_File-$date.csv" -Delimiter ";" -Append -NoTypeInformation 
    Write-Host "Created $PathtoFolder\exportNSG-$SUB_NAME_File-$date.csv" -ForegroundColor Green       
}

Write-Host "All done, please check $PathtoFolder" -ForegroundColor Green
#endregion