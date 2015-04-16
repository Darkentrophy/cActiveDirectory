Function Get-TargetResource {
    param (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [string]$GroupCategory,

        [Parameter(Mandatory)]
        [string]$GroupScope,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,
        
        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present'                   
    )
    try {
        Write-Verbose -Message "Checking if the group $GroupName in domain $DomainName is present ..."
        $group = Get-ADGroup -Identity $GroupName -Credential $DomainAdministratorCredential
        Write-Verbose -Message "Group $GroupName in domain $DomainName is present."
        $Ensure = 'Present' 
    }
    #Group not found
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose -Message "Group $GroupName account in domain $DomainName is NOT present"
        $Ensure = 'Absent'
    }
    catch {
        Write-Error -Message "Unhandled exception looking up $GroupName account in domain $DomainName."
        throw $_
    }

    @{
        DomainName = $DomainName
        GroupName = $GroupName
        GroupCategory = $GroupCategory
        GroupScope =  $GroupScope
        Path = $Path
        Ensure = $Ensure
    }
}

Function Set-TargetResource {
    param (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [string]$GroupCategory,

        [Parameter(Mandatory)]
        [string]$GroupScope,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,
        
        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present'                   
    )
    try {
        ValidateProperties @PSBoundParameters -Apply
    }
    catch {
        Write-Error -Message "Error setting ADGroup $GroupName in domain $DomainName. $_"
        throw $_
    }
}

Function Test-TargetResource {
    # TODO: Add parameters here
    # Make sure to use the same parameters for
    # Get-TargetResource, Set-TargetResource, and Test-TargetResource
    param (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [string]$GroupCategory,

        [Parameter(Mandatory)]
        [string]$GroupScope,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,
        
        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present'                   
    )

    try {
        $parameters = $PSBoundParameters.Remove('Debug');
        ValidateProperties @PSBoundParameters    
    }
    catch {
        Write-Error -Message "Error testing AD group $GroupName in domain $DomainName. $_"
        throw $_
    }
}


function ValidateProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$GroupName,

        [Parameter(Mandatory)]
        [string]$GroupCategory,

        [Parameter(Mandatory)]
        [string]$GroupScope,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,

        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present',          

        [Switch]$Apply
    )

    $result = $true
    # Check if group exists 

    try {
        Write-Verbose -Message "Checking if the group $GroupName in domain $DomainName is present ..."
        $group = Get-ADGroup -Identity $GroupName -Credential $DomainAdministratorCredential

        if(($group -ne $null)) {
            Write-Verbose -Message "Group $GroupName in domain $DomainName is present."
            if(!$Apply) {
                if( $Ensure -eq 'Absent' ) {
                    return $false
                }
                else {
                    return $($Ensure -eq 'Present')
                }
            }
        }
        
        if( $Ensure -eq 'Absent' ) {
            if( $Apply ) {
                Remove-ADGroup -Identity $GroupName -Credential $DomainAdministratorCredential -Confirm:$false
                Write-Verbose "Group $GroupName in $Domain has been removed"
                return $true
            }
            else {
                return $false
            }
        }
    }
    #Group not found
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose -Message "Group $GroupName account in domain $DomainName is NOT present"
        if($Apply) {

            if( $Ensure -ne 'Absent' ) {
                $params = @{ Name = $GroupName; SamAccountName = $GroupName; GroupCategory = $GroupCategory; GroupScope = $GroupScope; Path = $Path; Credential = $DomainAdministratorCredential }
                New-ADGRoup @params
                Write-Verbose -Message "Group $GroupName account in domain $DomainName has been created"
                #return $true
            }
        }
        else {
            return $($Ensure -eq 'Absent')
        }
    }
}

Export-ModuleMember -Function *-TargetResource
