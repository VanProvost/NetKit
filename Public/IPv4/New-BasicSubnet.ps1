# NetKit - Basic IPv4 Subnet Calculator
<#
.SYNOPSIS
    Divides an IPv4 network into equal-sized subnets.

.DESCRIPTION
    This function divides an IPv4 network into a specified number of equal-sized subnets.
    It accepts a network address with CIDR notation and creates the requested number of subnets,
    displaying network information for each subnet.

.PARAMETER NetworkCIDR
    A string containing a network address with CIDR notation (e.g., "192.168.0.0/24").

.PARAMETER NumberOfSubnets
    The number of equal-sized subnets to create. Must be a power of 2.

.PARAMETER HostsPerSubnet
    The minimum number of hosts required in each subnet. This is an alternative to specifying
    the number of subnets.

.PARAMETER IncludeUsableRange
    When specified, includes the range of usable IP addresses in each subnet.

.PARAMETER VerboseErrors
    Displays detailed error messages and processing information.

.PARAMETER Help
    Displays the help information for this function.

.EXAMPLE
    New-BasicSubnet -NetworkCIDR 192.168.0.0/24 -NumberOfSubnets 4
    
    Divides the 192.168.0.0/24 network into 4 equal subnets.

.EXAMPLE
    New-BasicSubnet -NetworkCIDR 10.0.0.0/16 -HostsPerSubnet 1000
    
    Divides the 10.0.0.0/16 network into subnets that can each accommodate at least 1000 hosts.

.EXAMPLE
    New-BasicSubnet 192.168.0.0/24 8 -IncludeUsableRange
    
    Divides the 192.168.0.0/24 network into 8 equal subnets and displays usable IP ranges.

.NOTES
    Part of the NetKit module.
#>
function New-BasicSubnet {
    [CmdletBinding(DefaultParameterSetName = 'NumberOfSubnets')]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$NetworkCIDR,
        
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'NumberOfSubnets')]
        [int]$NumberOfSubnets,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'HostsPerSubnet')]
        [int]$HostsPerSubnet,
        
        [Parameter()]
        [switch]$IncludeUsableRange,
        
        [Parameter()]
        [switch]$VerboseErrors,
        
        [Parameter(ParameterSetName = 'ShowHelp')]
        [switch]$Help
    )
    
    # Show help if requested
    if ($Help) { Get-Help New-BasicSubnet -Detailed; return }
    
    try {
        # Parse the input network CIDR
        if ($NetworkCIDR -match '(.+)/(\d+)') {
            $networkAddress = $matches[1]
            $networkCIDRPrefix = [int]$matches[2]
            
            if (-not (Test-IPv4Address -IP $networkAddress)) {
                Show-IPv4Error -Message "Invalid IP address: $networkAddress" -Example "New-BasicSubnet 192.168.0.0/24 4" -VerboseErrors:$VerboseErrors
                return
            }
            
            if ($networkCIDRPrefix -lt 0 -or $networkCIDRPrefix -gt 32) {
                Show-IPv4Error -Message "Invalid CIDR prefix: $networkCIDRPrefix" -Example "New-BasicSubnet 192.168.0.0/24 4" -VerboseErrors:$VerboseErrors
                return
            }
        }
        else {
            Show-IPv4Error -Message "Invalid network CIDR format" -Example "New-BasicSubnet 192.168.0.0/24 4" -VerboseErrors:$VerboseErrors
            return
        }
        
        # Calculate the required subnet bits
        if ($PSCmdlet.ParameterSetName -eq 'NumberOfSubnets') {
            # Validate NumberOfSubnets is a power of 2
            $log2 = [Math]::Log($NumberOfSubnets, 2)
            if ([Math]::Floor($log2) -ne $log2) {
                Show-IPv4Error -Message "Number of subnets must be a power of 2" -Example "New-BasicSubnet 192.168.0.0/24 4" -VerboseErrors:$VerboseErrors
                return
            }
            
            $subnetBits = [Math]::Log($NumberOfSubnets, 2)
        }
        else { # HostsPerSubnet parameter set
            # Calculate subnet bits based on required hosts
            $hostBits = [Math]::Ceiling([Math]::Log($HostsPerSubnet + 2, 2)) # +2 for network and broadcast addresses
            $availableHostBits = 32 - $networkCIDRPrefix
            
            if ($hostBits -gt $availableHostBits) {
                Show-IPv4Error -Message "Cannot accommodate $HostsPerSubnet hosts in subnets. Maximum possible is $([Math]::Pow(2, $availableHostBits) - 2)" -VerboseErrors:$VerboseErrors
                return
            }
            
            $subnetBits = $availableHostBits - $hostBits
            $NumberOfSubnets = [Math]::Pow(2, $subnetBits)
        }
        
        # Verify we're not exceeding the original network's capacity
        if (($networkCIDRPrefix + $subnetBits) -gt 32) {
            Show-IPv4Error -Message "Cannot create $NumberOfSubnets subnets within /$networkCIDRPrefix network" -VerboseErrors:$VerboseErrors
            return
        }
        
        # Calculate the new subnet mask
        $newCIDRPrefix = $networkCIDRPrefix + $subnetBits
        $subnetMask = ConvertTo-IPv4SubnetMask -PrefixLength $newCIDRPrefix
        
        # Get original network info to ensure we're working with the correct network address
        $networkInfo = Get-IPv4NetworkInfo -IPAddress $networkAddress -SubnetMask (ConvertTo-IPv4SubnetMask -PrefixLength $networkCIDRPrefix)
        $baseNetworkDecimal = ConvertTo-IPv4Decimal -IP $networkInfo.NetworkAddress
        
        # Calculate the subnet size
        $subnetSize = [Math]::Pow(2, (32 - $newCIDRPrefix))
        
        # Create subnets
        $subnets = @()
        
        for ($i = 0; $i -lt $NumberOfSubnets; $i++) {
            $subnetNetworkDecimal = $baseNetworkDecimal + ($i * $subnetSize)
            $subnetNetworkAddress = ConvertTo-IPv4DottedDecimal -IPDecimal $subnetNetworkDecimal
            
            $subnet = Get-IPv4NetworkInfo -IPAddress $subnetNetworkAddress -SubnetMask $subnetMask -IncludeUsableRange:$IncludeUsableRange
            $subnets += $subnet
        }
        
        # Return results
        Write-Output "Original Network: $($networkInfo.CIDR)"
        Write-Output "Dividing into $NumberOfSubnets equal subnets (/$newCIDRPrefix)"
        Write-Output ""
        
        # Format and output subnet information
        $formatTable = @()
        
        foreach ($subnet in $subnets) {
            $subnetObj = [PSCustomObject]@{
                'Subnet'      = $subnet.CIDR
                'Network'     = $subnet.NetworkAddress
                'Broadcast'   = $subnet.BroadcastAddress
                'Mask'        = $subnet.Mask
            }
            
            if ($IncludeUsableRange) {
                $subnetObj | Add-Member -MemberType NoteProperty -Name 'UsableRange' -Value $subnet.UsableRange
                $subnetObj | Add-Member -MemberType NoteProperty -Name 'UsableHosts' -Value $subnet.UsableHosts
            }
            
            $formatTable += $subnetObj
        }
        
        return $formatTable
    }
    catch {
        if ($VerboseErrors) {
            Write-Error $_
        }
        else {
            Show-IPv4Error -Message "Failed to calculate subnets" -VerboseErrors:$VerboseErrors
        }
    }
}