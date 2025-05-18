# NetKit - IPv6 Calculator
<#
.SYNOPSIS
    IPv6 Calculator - Calculates and displays IPv6 network information.

.DESCRIPTION
    This function calculates IPv6 network information based on an IPv6 address and prefix length.
    It provides information such as network prefix, expanded address, compressed address, and network size.

.PARAMETER InputString
    A string containing an IPv6 address with prefix notation (e.g., "2001:db8::1/64").

.PARAMETER IPv6Address
    The IPv6 address to analyze.

.PARAMETER PrefixLength
    The IPv6 prefix length (e.g., 64 for a /64 network).

.PARAMETER VerboseErrors
    Displays detailed error messages and processing information.

.PARAMETER Help
    Displays the help information for this function.

.EXAMPLE
    Invoke-IPv6Calc 2001:db8::1/64
    
    Calculates network information for the given IPv6 address and prefix.

.EXAMPLE
    Invoke-IPv6Calc -IPv6Address 2001:db8::1 -PrefixLength 48
    
    Calculates network information using the IPv6 address and prefix length.

.NOTES
    Part of the NetKit module.
#>
function Invoke-IPv6Calc {
    [CmdletBinding(DefaultParameterSetName = 'IPv6Prefix')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'PrefixString')]
        [string]$InputString,

        [Parameter(Mandatory = $true, ParameterSetName = 'IPv6Prefix')]
        [string]$IPv6Address,

        [Parameter(Mandatory = $true, ParameterSetName = 'IPv6Prefix')]
        [ValidateRange(0, 128)]
        [int]$PrefixLength,
        
        [Parameter(ParameterSetName = 'ShowHelp')]
        [switch]$Help,
        
        [Parameter()]
        [switch]$VerboseErrors
    )

    # Show help if requested
    if ($Help) { Get-Help Invoke-IPv6Calc -Detailed; return }

    # Main processing block
    try {
        # Handle different input formats
        switch ($PSCmdlet.ParameterSetName) {
            'PrefixString' {
                if ($InputString -match '(.+)/(\d+)') {
                    $IPv6Address = $matches[1]
                    $PrefixLength = [int]$matches[2]
                    
                    if (-not (Test-IPv6Address -IP $IPv6Address)) {
                        Show-IPv6Error -Message "Invalid IPv6 address: $IPv6Address" -Example "Invoke-IPv6Calc 2001:db8::1/64" -VerboseErrors:$VerboseErrors
                        return
                    }
                    if ($PrefixLength -lt 0 -or $PrefixLength -gt 128) {
                        Show-IPv6Error -Message "Invalid prefix length: $PrefixLength" -Example "Invoke-IPv6Calc 2001:db8::1/64" -VerboseErrors:$VerboseErrors
                        return
                    }
                }
                else {
                    Show-IPv6Error -Message "Invalid input format" -Example "Invoke-IPv6Calc 2001:db8::1/64" -VerboseErrors:$VerboseErrors
                    return
                }
            }
            
            'IPv6Prefix' {
                if (-not (Test-IPv6Address -IP $IPv6Address)) {
                    Show-IPv6Error -Message "Invalid IPv6 address: $IPv6Address" -Example "Invoke-IPv6Calc -IPv6Address 2001:db8::1 -PrefixLength 64" -VerboseErrors:$VerboseErrors
                    return
                }
            }
        }

        # Get the network information
        $result = Get-IPv6NetworkInfo -IPv6Address $IPv6Address -PrefixLength $PrefixLength
        
        if ($null -eq $result) {
            Show-IPv6Error -Message "Failed to calculate IPv6 network information" -VerboseErrors:$VerboseErrors
            return
        }
        
        # Return the result
        return $result
    }
    catch {
        if ($VerboseErrors) { 
            Write-Error $_ 
        }
        else { 
            Show-IPv6Error -Message "Failed to calculate IPv6 network information" -VerboseErrors:$VerboseErrors
        }
    }
}