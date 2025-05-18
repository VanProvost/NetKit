<#
.SYNOPSIS
    IP Calculator (IPCalc) - Calculates and displays subnet information from various input formats.

.DESCRIPTION
    This script calculates IP subnet information based on different inputs:
    - IP address and CIDR notation
    - IP address and subnet mask
    - Network address and broadcast address
    
    The script provides detailed subnet information including subnet mask, CIDR notation,
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
    Displays the help information for this script.
#>

function Invoke-IPCalc {
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
    if ($Help) { Get-Help Invoke-IPCalc -Detailed; return }

    # Function to show error message
    function Show-Error {
        param([string]$Message, [string]$Example = "")
        
        if ($VerboseErrors) { Write-Error $Message }
        else {
            Write-Host "Error: $Message" -ForegroundColor Red
            if ($Example) {
                Write-Host "`nExample usage:" -ForegroundColor Yellow
                Write-Host "  $Example" -ForegroundColor Cyan
            }
        }
    }

    # Function to validate IP address using .NET method
    function Test-ValidIPAddress {
        param ([string]$IP)
        
        try {
            [System.Net.IPAddress]::TryParse($IP, [ref]$null)
        }
        catch {
            if ($VerboseErrors) { Write-Verbose "Error validating IP: $_" }
            return $false
        }
    }

    # Function to convert IP string to decimal using .NET method
    function ConvertTo-DecimalIP {
        param ([string]$IP)
        
        try {
            $ipAddress = [System.Net.IPAddress]::Parse($IP)
            [BitConverter]::ToUInt32($ipAddress.GetAddressBytes(), 0)
        }
        catch {
            if ($VerboseErrors) { Write-Error "Failed to convert IP to decimal: $_" }
            return $null
        }
    }

    # Function to convert decimal to IP string using .NET method
    function ConvertTo-DottedIP {
        param ([long]$IPDecimal)
        
        try {
            [System.Net.IPAddress]::new([BitConverter]::GetBytes($IPDecimal)).ToString()
        }
        catch {
            if ($VerboseErrors) { Write-Error "Failed to convert decimal to IP: $_" }
            return "Error"
        }
    }

    # Function to convert CIDR to subnet mask using efficient data structures
    function ConvertTo-SubnetMask {
        param ([int]$PrefixLength)
        
        if ($PrefixLength -lt 0 -or $PrefixLength -gt 32) {
            Show-Error "Invalid prefix length. Must be between 0 and 32."
            return $null
        }
        
        try {
            $mask = [UInt32]::MaxValue -shl (32 - $PrefixLength)
            return "$([byte](($mask -band 0xFF000000) -shr 24)).$([byte](($mask -band 0x00FF0000) -shr 16)).$([byte](($mask -band 0x0000FF00) -shr 8)).$([byte]($mask -band 0x000000FF))"
        }
        catch {
            if ($VerboseErrors) { Write-Error "Failed to convert CIDR to subnet mask: $_" }
            return $null
        }
    }

    # Function to convert subnet mask to CIDR using efficient data structures
    function ConvertTo-CIDR {
        param ([string]$SubnetMask)
        
        try {
            $decimalMask = ConvertTo-DecimalIP $SubnetMask
            if ($null -eq $decimalMask) { return $null }
            
            $binary = [Convert]::ToString($decimalMask, 2)
            return ($binary -replace '0', '').Length
        }
        catch {
            if ($VerboseErrors) { Write-Error "Failed to convert subnet mask to CIDR: $_" }
            return $null
        }
    }

    # Main processing block
    try {
        # Handle different input formats
        $validInput = $true
        switch ($PSCmdlet.ParameterSetName) {
            'CIDRString' {
                if ($InputString -match '(.+)/(\d+)') {
                    $IPAddress = $matches[1]
                    $CIDR = [int]$matches[2]
                    
                    if (-not (Test-ValidIPAddress $IPAddress)) {
                        Show-Error "Invalid IP address: $IPAddress" "Invoke-IPCalc 192.168.1.1/24"
                        return
                    }
                    if ($CIDR -lt 0 -or $CIDR -gt 32) {
                        Show-Error "Invalid CIDR prefix: $CIDR" "Invoke-IPCalc 192.168.1.1/24"
                        return
                    }
                    
                    $mask = ConvertTo-SubnetMask $CIDR
                }
                else {
                    Show-Error "Invalid input format" "Invoke-IPCalc 192.168.1.1/24"
                    return
                }
            }
            
            'IPCIDR' {
                if (-not (Test-ValidIPAddress $IPAddress)) {
                    Show-Error "Invalid IP address: $IPAddress" "Invoke-IPCalc -IPAddress 192.168.1.1 -CIDR 24"
                    return
                }
                $mask = ConvertTo-SubnetMask $CIDR
            }
            
            'IPSubnet' {
                if (-not (Test-ValidIPAddress $IPAddress)) {
                    Show-Error "Invalid IP address: $IPAddress" "Invoke-IPCalc -IPAddress 192.168.1.1 -SubnetMask 255.255.255.0"
                    return
                }
                if (-not (Test-ValidIPAddress $SubnetMask)) {
                    Show-Error "Invalid subnet mask: $SubnetMask" "Invoke-IPCalc -IPAddress 192.168.1.1 -SubnetMask 255.255.255.0"
                    return
                }
                
                $decimalMask = ConvertTo-DecimalIP $SubnetMask
                $binary = [Convert]::ToString($decimalMask, 2)
                if ($binary -match '01') {
                    Show-Error "Invalid subnet mask pattern: $SubnetMask"
                    return
                }
                
                $mask = $SubnetMask
                $CIDR = ConvertTo-CIDR $SubnetMask
            }
            
            'NetBroadcast' {
                if (-not (Test-ValidIPAddress $NetworkAddress)) {
                    Show-Error "Invalid network address: $NetworkAddress" "Invoke-IPCalc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255"
                    return
                }
                if (-not (Test-ValidIPAddress $BroadcastAddress)) {
                    Show-Error "Invalid broadcast address: $BroadcastAddress" "Invoke-IPCalc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255"
                    return
                }
                
                $netDecimal = ConvertTo-DecimalIP $NetworkAddress
                $broadcastDecimal = ConvertTo-DecimalIP $BroadcastAddress
                
                if ($netDecimal -gt $broadcastDecimal) {
                    Show-Error "Network address must be less than broadcast address"
                    return
                }
                
                $range = $broadcastDecimal - $netDecimal + 1
                $log2 = [Math]::Log($range, 2)
                
                if ([Math]::Truncate($log2) -ne $log2) {
                    Show-Error "Invalid subnet range: must be a power of 2" "Invoke-IPCalc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255"
                    return
                }
                
                $CIDR = 32 - $log2
                $mask = ConvertTo-SubnetMask $CIDR
                $IPAddress = $NetworkAddress
            }
        }

        if ($null -eq $mask) { return }
        
        # Calculate subnet information
        $ipDecimal = ConvertTo-DecimalIP $IPAddress
        $maskDecimal = ConvertTo-DecimalIP $mask
        $networkDecimal = $ipDecimal -band $maskDecimal
        $wildcardDecimal = -bnot $maskDecimal
        $broadcastDecimal = $networkDecimal -bor $wildcardDecimal

        $networkAddress = ConvertTo-DottedIP $networkDecimal
        $broadcastAddress = ConvertTo-DottedIP $broadcastDecimal
        $wildcardMask = ConvertTo-DottedIP $wildcardDecimal
        
        # Build output object
        $output = [PSCustomObject]@{
            IPAddress    = $IPAddress
            Mask         = $mask
            PrefixLength = $CIDR
            WildCard     = $wildcardMask
            Subnet       = $networkAddress
            Broadcast    = $broadcastAddress
            CIDR         = "$networkAddress/$CIDR"
        }

        # Add UsableRange if requested
        if ($UsableRange) {
            if ($CIDR -eq 32) {
                $usableRangeValue = "$networkAddress"
            }
            elseif ($CIDR -eq 31) {
                $usableRangeValue = "$networkAddress-$broadcastAddress"
            }
            else {
                $firstHost = ConvertTo-DottedIP ($networkDecimal + 1)
                $lastHost = ConvertTo-DottedIP ($broadcastDecimal - 1)
                $usableRangeValue = "$firstHost-$lastHost"
            }
            
            $output | Add-Member -MemberType NoteProperty -Name "UsableRange" -Value $usableRangeValue
        }

        # Display result
        $output | Format-List
    }
    catch {
        if ($VerboseErrors) { Write-Error $_ }
        else { Show-Error "Failed to calculate subnet information" }
    }
}

# Create alias for easier use
#Set-Alias -Name IPCalc -Value Invoke-IPCalc

# Export the function and alias if script is imported as a module
#Export-ModuleMember -Function Invoke-IPCalc -Alias IPCalc
