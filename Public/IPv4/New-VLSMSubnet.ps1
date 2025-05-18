# NetKit - Variable Length Subnet Mask (VLSM) Calculator
<#
.SYNOPSIS
    Creates subnets of different sizes using VLSM.

.DESCRIPTION
    This function implements Variable Length Subnet Mask (VLSM) to create subnets of different sizes
    from a base network. It allows you to specify the required number of hosts for each subnet
    and efficiently allocates address space.

.PARAMETER NetworkCIDR
    A string containing a network address with CIDR notation (e.g., "192.168.0.0/24").

.PARAMETER HostsPerSubnet
    An array of integers representing the number of hosts required for each subnet.
    The subnets will be created in order of size (largest to smallest) for optimal allocation.

.PARAMETER SubnetNames
    Optional array of names to assign to each subnet, corresponding to the HostsPerSubnet array.

.PARAMETER IncludeUsableRange
    When specified, includes the range of usable IP addresses in each subnet.

.PARAMETER VerboseErrors
    Displays detailed error messages and processing information.

.PARAMETER Help
    Displays the help information for this function.

.EXAMPLE
    New-VLSMSubnet -NetworkCIDR 192.168.0.0/24 -HostsPerSubnet 100,50,25,10
    
    Creates four subnets from 192.168.0.0/24 with enough space for 100, 50, 25, and 10 hosts respectively.

.EXAMPLE
    New-VLSMSubnet -NetworkCIDR 10.0.0.0/16 -HostsPerSubnet 1000,500,250,100 -SubnetNames "HQ","Branch1","Branch2","Guest"
    
    Creates four named subnets with the specified host requirements.

.EXAMPLE
    New-VLSMSubnet 192.168.0.0/24 @(50,20,10) -IncludeUsableRange
    
    Creates three subnets with usable IP ranges displayed.

.NOTES
    Part of the NetKit module.
#>
function New-VLSMSubnet {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$NetworkCIDR,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [int[]]$HostsPerSubnet,
        
        [Parameter()]
        [string[]]$SubnetNames,
        
        [Parameter()]
        [switch]$IncludeUsableRange,
        
        [Parameter()]
        [switch]$VerboseErrors,
        
        [Parameter(ParameterSetName = 'ShowHelp')]
        [switch]$Help
    )
    
    # Show help if requested
    if ($Help) { Get-Help New-VLSMSubnet -Detailed; return }
    
    try {
        # Parse the input network CIDR
        if ($NetworkCIDR -match '(.+)/(\d+)') {
            $networkAddress = $matches[1]
            $networkCIDRPrefix = [int]$matches[2]
            
            if (-not (Test-IPv4Address -IP $networkAddress)) {
                Show-IPv4Error -Message "Invalid IP address: $networkAddress" -Example "New-VLSMSubnet 192.168.0.0/24 100,50,25" -VerboseErrors:$VerboseErrors
                return
            }
            
            if ($networkCIDRPrefix -lt 0 -or $networkCIDRPrefix -gt 32) {
                Show-IPv4Error -Message "Invalid CIDR prefix: $networkCIDRPrefix" -Example "New-VLSMSubnet 192.168.0.0/24 100,50,25" -VerboseErrors:$VerboseErrors
                return
            }
        }
        else {
            Show-IPv4Error -Message "Invalid network CIDR format" -Example "New-VLSMSubnet 192.168.0.0/24 100,50,25" -VerboseErrors:$VerboseErrors
            return
        }
        
        # Verify subnet names if provided
        if ($SubnetNames -and $SubnetNames.Count -ne $HostsPerSubnet.Count) {
            Show-IPv4Error -Message "Number of subnet names ($($SubnetNames.Count)) doesn't match number of subnets ($($HostsPerSubnet.Count))" -VerboseErrors:$VerboseErrors
            return
        }
        
        # Calculate required bits for each subnet - use a pre-sized array for better performance
        $hostsCount = $HostsPerSubnet.Count
        $subnetRequirements = [System.Collections.ArrayList]::new($hostsCount)
        
        # Pre-calculate powers of 2 to avoid repetitive calculations
        $log2 = 2.0
        $powers = @()
        for ($i = 1; $i -le 31; $i++) {
            $powers += [PSCustomObject]@{
                Bits = $i
                Hosts = [math]::Pow(2, $i)
            }
        }
        
        for ($i = 0; $i -lt $hostsCount; $i++) {
            $hosts = $HostsPerSubnet[$i]
            # More efficient calculation using pre-calculated powers
            $hostBitsObj = $powers | Where-Object { $_.Hosts -ge ($hosts + 2) } | Select-Object -First 1
            if ($null -eq $hostBitsObj) {
                $hostBits = 31  # Maximum possible for IPv4
            }
            else {
                $hostBits = $hostBitsObj.Bits
            }
            
            $cidrPrefix = 32 - $hostBits
            $name = if ($SubnetNames -and $i -lt $SubnetNames.Count) { $SubnetNames[$i] } else { "Subnet $($i+1)" }
            
            [void]$subnetRequirements.Add([PSCustomObject]@{
                Name = $name
                HostsNeeded = $hosts
                HostBits = $hostBits
                CIDRPrefix = $cidrPrefix
                ActualHosts = [Math]::Pow(2, $hostBits) - 2
            })
        }
        
        # Sort by size (largest first) for optimal allocation - use in-place sorting for better performance
        $subnetRequirements = $subnetRequirements | Sort-Object -Property CIDRPrefix
        
        # Get the original network details
        $networkMask = ConvertTo-IPv4SubnetMask -PrefixLength $networkCIDRPrefix
        $networkInfo = Get-IPv4NetworkInfo -IPAddress $networkAddress -SubnetMask $networkMask
        $availableAddressSpace = [Math]::Pow(2, (32 - $networkCIDRPrefix))
        
        # Calculate total required address space more efficiently
        $totalRequiredAddressSpace = 0
        foreach ($subnet in $subnetRequirements) {
            $subnetSize = [Math]::Pow(2, (32 - $subnet.CIDRPrefix))
            $totalRequiredAddressSpace += $subnetSize
        }
        
        # Check if we have enough address space
        if ($totalRequiredAddressSpace -gt $availableAddressSpace) {
            Show-IPv4Error -Message "Not enough address space in $NetworkCIDR for all required subnets. Need $totalRequiredAddressSpace addresses, but only have $availableAddressSpace." -VerboseErrors:$VerboseErrors
            return
        }
        
        # Allocate subnets - use ArrayList for better performance with large collections
        $currentNetworkDecimal = ConvertTo-IPv4Decimal -IP $networkInfo.NetworkAddress
        $allocatedSubnets = [System.Collections.ArrayList]::new($subnetRequirements.Count)
        
        foreach ($subnet in $subnetRequirements) {
            $subnetSize = [Math]::Pow(2, (32 - $subnet.CIDRPrefix))
            $subnetMask = ConvertTo-IPv4SubnetMask -PrefixLength $subnet.CIDRPrefix
            $subnetNetworkAddress = ConvertTo-IPv4DottedDecimal -IPDecimal $currentNetworkDecimal
            
            # Get detailed subnet info
            $subnetInfo = Get-IPv4NetworkInfo -IPAddress $subnetNetworkAddress -SubnetMask $subnetMask -IncludeUsableRange:$IncludeUsableRange
            
            # Add custom properties for VLSM info
            $subnetInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value $subnet.Name
            $subnetInfo | Add-Member -MemberType NoteProperty -Name "RequiredHosts" -Value $subnet.HostsNeeded
            
            [void]$allocatedSubnets.Add($subnetInfo)
            
            # Move to next subnet starting address
            $currentNetworkDecimal += $subnetSize
        }
        
        # Return results
        Write-Output "Original Network: $($networkInfo.CIDR)"
        Write-Output "VLSM Allocation for $($subnetRequirements.Count) subnets"
        Write-Output "Total Address Space Required: $totalRequiredAddressSpace addresses"
        Write-Output "Available Address Space: $availableAddressSpace addresses"
        Write-Output ""
        
        # Format and output subnet information more efficiently
        $formatTable = [System.Collections.ArrayList]::new($allocatedSubnets.Count)
        
        foreach ($subnet in $allocatedSubnets) {
            $subnetObj = [PSCustomObject]@{
                'Name'        = $subnet.Name
                'Subnet'      = $subnet.CIDR
                'Mask'        = $subnet.Mask
                'Required'    = $subnet.RequiredHosts
                'Available'   = if ($subnet.UsableHosts) { $subnet.UsableHosts } else { [Math]::Pow(2, (32 - $subnet.PrefixLength)) - 2 }
            }
            
            if ($IncludeUsableRange) {
                $subnetObj | Add-Member -MemberType NoteProperty -Name 'UsableRange' -Value $subnet.UsableRange
            }
            
            [void]$formatTable.Add($subnetObj)
        }
        
        return $formatTable
    }
    catch {
        if ($VerboseErrors) {
            Write-Error $_
        }
        else {
            Show-IPv4Error -Message "Failed to calculate VLSM subnets" -VerboseErrors:$VerboseErrors
        }
    }
}
