# NetKit - IPv4 Calculator
<#
.SYNOPSIS
    IPv4 Calculator - Calculates and displays subnet information from various input formats.

.DESCRIPTION
    This function calculates IPv4 subnet information based on different inputs:
    - IP address and CIDR notation
    - IP address and subnet mask
    - Network address and broadcast address
    
    The function provides detailed subnet information including subnet mask, CIDR notation,
    wildcard mask, network address, and broadcast address.

.PARAMETER InputString
    A string containing an IP address with CIDR notation (e.g., "192.168.1.1/24").

.PARAMETER IPAddress
    The IP address to analyze.

.PARAMETER SubnetMask
    The subnet mask in dotted decimal notation (e.g., 255.255.255.0).

.PARAMETER CIDR
    The CIDR prefix length (e.g., 24 for a /24 network).

.PARAMETER NetworkAddress
    The network address of the subnet.

.PARAMETER BroadcastAddress
    The broadcast address of the subnet.

.PARAMETER UsableRange
    When specified, calculates and displays the range of usable IP addresses in the subnet.

.PARAMETER VerboseErrors
    Displays detailed error messages and processing information.

.PARAMETER Help
    Displays the help information for this function.

.EXAMPLE
    Invoke-IPv4Calc 192.168.1.1/24
    
    Calculates subnet information for the given IP and CIDR notation.

.EXAMPLE
    Invoke-IPv4Calc -IPAddress 192.168.1.1 -CIDR 24
    
    Calculates subnet information using the IP address and CIDR prefix.

.EXAMPLE
    Invoke-IPv4Calc -IPAddress 10.0.0.15 -SubnetMask 255.255.255.0 -UsableRange
    
    Calculates subnet information using an IP address and subnet mask, and includes the usable IP range.

.EXAMPLE
    Invoke-IPv4Calc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255
    
    Calculates subnet information from the network and broadcast addresses.

.NOTES
    Part of the NetKit module.
#>
function Invoke-IPv4Calc {
    [CmdletBinding(DefaultParameterSetName = 'IPCIDR')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'CIDRString')]
        [string]$InputString,

        [Parameter(Mandatory = $true, ParameterSetName = 'IPCIDR')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IPSubnet')]
        [string]$IPAddress,

        [Parameter(Mandatory = $true, ParameterSetName = 'IPCIDR')]
        [ValidateRange(0, 32)]
        [int]$CIDR,

        [Parameter(Mandatory = $true, ParameterSetName = 'IPSubnet')]
        [string]$SubnetMask,

        [Parameter(Mandatory = $true, ParameterSetName = 'NetBroadcast')]
        [string]$NetworkAddress,

        [Parameter(Mandatory = $true, ParameterSetName = 'NetBroadcast')]
        [string]$BroadcastAddress,
        
        [Parameter(ParameterSetName = 'ShowHelp')]
        [switch]$Help,
        
        [Parameter()]
        [switch]$UsableRange,
        
        [Parameter()]
        [switch]$VerboseErrors
    )

    # Show help if requested
    if ($Help) { Get-Help Invoke-IPv4Calc -Detailed; return }

    # Main processing block
    try {
        # Handle different input formats
        switch ($PSCmdlet.ParameterSetName) {
            'CIDRString' {
                if ($InputString -match '(.+)/(\d+)') {
                    $IPAddress = $matches[1]
                    $CIDR = [int]$matches[2]
                    
                    if (-not (Test-IPv4Address -IP $IPAddress)) {
                        Show-IPv4Error -Message "Invalid IP address: $IPAddress" -Example "Invoke-IPv4Calc 192.168.1.1/24" -VerboseErrors:$VerboseErrors
                        return
                    }
                    if ($CIDR -lt 0 -or $CIDR -gt 32) {
                        Show-IPv4Error -Message "Invalid CIDR prefix: $CIDR" -Example "Invoke-IPv4Calc 192.168.1.1/24" -VerboseErrors:$VerboseErrors
                        return
                    }
                    
                    $mask = ConvertTo-IPv4SubnetMask -PrefixLength $CIDR
                }
                else {
                    Show-IPv4Error -Message "Invalid input format" -Example "Invoke-IPv4Calc 192.168.1.1/24" -VerboseErrors:$VerboseErrors
                    return
                }
            }
            
            'IPCIDR' {
                if (-not (Test-IPv4Address -IP $IPAddress)) {
                    Show-IPv4Error -Message "Invalid IP address: $IPAddress" -Example "Invoke-IPv4Calc -IPAddress 192.168.1.1 -CIDR 24" -VerboseErrors:$VerboseErrors
                    return
                }
                $mask = ConvertTo-IPv4SubnetMask -PrefixLength $CIDR
            }
            
            'IPSubnet' {
                if (-not (Test-IPv4Address -IP $IPAddress)) {
                    Show-IPv4Error -Message "Invalid IP address: $IPAddress" -Example "Invoke-IPv4Calc -IPAddress 192.168.1.1 -SubnetMask 255.255.255.0" -VerboseErrors:$VerboseErrors
                    return
                }
                if (-not (Test-IPv4Address -IP $SubnetMask) -or -not (Test-IPv4SubnetMask -SubnetMask $SubnetMask)) {
                    Show-IPv4Error -Message "Invalid subnet mask: $SubnetMask" -Example "Invoke-IPv4Calc -IPAddress 192.168.1.1 -SubnetMask 255.255.255.0" -VerboseErrors:$VerboseErrors
                    return
                }
                
                $mask = $SubnetMask
                $CIDR = ConvertTo-IPv4CIDR -SubnetMask $SubnetMask
            }
            
            'NetBroadcast' {
                if (-not (Test-IPv4Address -IP $NetworkAddress)) {
                    Show-IPv4Error -Message "Invalid network address: $NetworkAddress" -Example "Invoke-IPv4Calc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255" -VerboseErrors:$VerboseErrors
                    return
                }
                if (-not (Test-IPv4Address -IP $BroadcastAddress)) {
                    Show-IPv4Error -Message "Invalid broadcast address: $BroadcastAddress" -Example "Invoke-IPv4Calc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255" -VerboseErrors:$VerboseErrors
                    return
                }
                
                $netDecimal = ConvertTo-IPv4Decimal -IP $NetworkAddress
                $broadcastDecimal = ConvertTo-IPv4Decimal -IP $BroadcastAddress
                
                if ($netDecimal -gt $broadcastDecimal) {
                    Show-IPv4Error -Message "Network address must be less than broadcast address" -VerboseErrors:$VerboseErrors
                    return
                }
                
                $range = $broadcastDecimal - $netDecimal + 1
                $log2 = [Math]::Log($range, 2)
                
                if ([Math]::Truncate($log2) -ne $log2) {
                    Show-IPv4Error -Message "Invalid subnet range: must be a power of 2" -Example "Invoke-IPv4Calc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255" -VerboseErrors:$VerboseErrors
                    return
                }
                
                $CIDR = 32 - $log2
                $mask = ConvertTo-IPv4SubnetMask -PrefixLength $CIDR
                $IPAddress = $NetworkAddress
            }
        }

        if ($null -eq $mask) { return }

        # Get the network information
        $result = Get-IPv4NetworkInfo -IPAddress $IPAddress -SubnetMask $mask -IncludeUsableRange:$UsableRange
        
        # Return the result
        return $result
    }
    catch {
        if ($VerboseErrors) { 
            Write-Error $_ 
        }
        else { 
            Show-IPv4Error -Message "Failed to calculate subnet information" -VerboseErrors:$VerboseErrors
        }
    }
}
