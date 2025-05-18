# NetKit - IPv6 Helper Functions
# These functions are internal and not directly exported to users

function Show-IPv6Error {
    [CmdletBinding()]
    param(
        [string]$Message,
        [string]$Example = "",
        [switch]$VerboseErrors
    )
    
    if ($VerboseErrors) { 
        Write-Error $Message 
    }
    else {
        Write-Host "Error: $Message" -ForegroundColor Red
        if ($Example) {
            Write-Host "`nExample usage:" -ForegroundColor Yellow
            Write-Host "  $Example" -ForegroundColor Cyan
        }
    }
}

function Test-IPv6Address {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP
    )
    
    try {
        # Use .NET to validate the IPv6 address format
        $address = [System.Net.IPAddress]::Parse($IP)
        return $address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6
    }
    catch {
        return $false
    }
}

function ConvertTo-IPv6Compressed {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPv6Address
    )
    
    try {
        $address = [System.Net.IPAddress]::Parse($IPv6Address)
        if ($address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            return $null
        }
        
        # Use IPAddress's ToString() method to get the compressed format
        return $address.ToString()
    }
    catch {
        return $null
    }
}

function ConvertTo-IPv6Expanded {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPv6Address
    )
    
    try {
        $address = [System.Net.IPAddress]::Parse($IPv6Address)
        if ($address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            return $null
        }
        
        # Get the bytes and format them as expanded IPv6
        $bytes = $address.GetAddressBytes()
        $hexGroups = @()
        
        for ($i = 0; $i -lt $bytes.Length; $i += 2) {
            $hexGroups += "{0:x4}" -f ([int]$bytes[$i] * 256 + [int]$bytes[$i+1])
        }
        
        return $hexGroups -join ":"
    }
    catch {
        return $null
    }
}

function Get-IPv6NetworkInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPv6Address,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 128)]
        [int]$PrefixLength
    )
    
    try {
        # Parse the IPv6 address
        $ipObj = [System.Net.IPAddress]::Parse($IPv6Address)
        if ($ipObj.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            Write-Verbose "Address '$IPv6Address' is not a valid IPv6 address"
            return $null
        }
        
        # Get address bytes
        $bytes = $ipObj.GetAddressBytes()
        
        # Calculate network prefix bytes - use proper array instantiation
        $networkBytes = [byte[]]::new(16)
        [Array]::Copy($bytes, $networkBytes, 16)
        
        # Apply the prefix mask
        $fullBytes = [Math]::Floor($PrefixLength / 8)
        $remainingBits = $PrefixLength % 8
        
        # Zero out bytes beyond the prefix length
        if ($fullBytes -lt 16) {
            # Handle partial byte
            if ($remainingBits -gt 0) {
                $mask = [byte](0xFF -shl (8 - $remainingBits))
                $networkBytes[$fullBytes] = $networkBytes[$fullBytes] -band $mask
            }
            
            # Zero out remaining bytes - optimize with a more efficient loop
            $startIndex = $fullBytes + $(if ($remainingBits -gt 0) { 1 } else { 0 })
            if ($startIndex -lt 16) {
                for ($i = $startIndex; $i -lt 16; $i++) {
                    $networkBytes[$i] = 0
                }
            }
        }
        
        # Create the network address
        $networkAddress = [System.Net.IPAddress]::new($networkBytes)
        
        # Calculate the last address in the network
        $lastAddressBytes = [byte[]]::new(16)
        [Array]::Copy($networkBytes, $lastAddressBytes, 16)
        
        # Set the bits beyond prefix to 1
        if ($fullBytes -lt 16) {
            # Handle partial byte
            if ($remainingBits -gt 0) {
                $mask = [byte]((1 -shl (8 - $remainingBits)) - 1)
                $lastAddressBytes[$fullBytes] = $lastAddressBytes[$fullBytes] -bor $mask
            }
            
            # Set remaining bytes to 0xFF - optimize with more efficient loop
            $startIndex = $fullBytes + $(if ($remainingBits -gt 0) { 1 } else { 0 })
            if ($startIndex -lt 16) {
                for ($i = $startIndex; $i -lt 16; $i++) {
                    $lastAddressBytes[$i] = 0xFF
                }
            }
        }
        
        $lastAddress = [System.Net.IPAddress]::new($lastAddressBytes)
        
        # Calculate total addresses in the network - use static method for better performance
        $totalAddresses = [System.Math]::Pow(2, (128 - $PrefixLength))
        $totalAddressesStr = if ($totalAddresses -gt [double]::MaxValue) {
            "2^$((128 - $PrefixLength))"
        } else {
            $totalAddresses.ToString("N0")
        }
        
        # Build the result object using compact syntax for better readability
        $result = [PSCustomObject]@{
            IPv6Address        = $IPv6Address
            CompressedAddress  = $ipObj.ToString()
            ExpandedAddress    = (ConvertTo-IPv6Expanded $IPv6Address)
            PrefixLength       = $PrefixLength
            NetworkAddress     = $networkAddress.ToString()
            NetworkPrefix      = "$($networkAddress.ToString())/$PrefixLength"
            LastAddress        = $lastAddress.ToString()
            TotalAddresses     = $totalAddressesStr
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to calculate IPv6 network information: $_"
        return $null
    }
}