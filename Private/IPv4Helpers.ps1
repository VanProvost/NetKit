# NetKit - IPv4 Helper Functions
# These functions are internal and not directly exported to users

function Show-IPv4Error {
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

function Test-IPv4Address {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP
    )
    
    try {
        [System.Net.IPAddress]::TryParse($IP, [ref]$null)
    }
    catch {
        Write-Verbose "Error validating IPv4 address: $_"
        return $false
    }
}

function ConvertTo-IPv4Decimal {
    [CmdletBinding()]
    [OutputType([long])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP
    )
    
    try {
        $ipAddress = [System.Net.IPAddress]::Parse($IP)
        [BitConverter]::ToUInt32($ipAddress.GetAddressBytes(), 0)
    }
    catch {
        Write-Verbose "Failed to convert IP to decimal: $_"
        return $null
    }
}

function ConvertTo-IPv4DottedDecimal {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [long]$IPDecimal
    )
    
    try {
        [System.Net.IPAddress]::new([BitConverter]::GetBytes($IPDecimal)).ToString()
    }
    catch {
        Write-Verbose "Failed to convert decimal to IP: $_"
        return $null
    }
}

function ConvertTo-IPv4SubnetMask {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 32)]
        [int]$PrefixLength
    )
    
    try {
        $mask = [UInt32]::MaxValue -shl (32 - $PrefixLength)
        return "$([byte](($mask -band 0xFF000000) -shr 24)).$([byte](($mask -band 0x00FF0000) -shr 16)).$([byte](($mask -band 0x0000FF00) -shr 8)).$([byte]($mask -band 0x000000FF))"
    }
    catch {
        Write-Verbose "Failed to convert prefix length to subnet mask: $_"
        return $null
    }
}

function ConvertTo-IPv4CIDR {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubnetMask
    )
    
    try {
        $decimalMask = ConvertTo-IPv4Decimal $SubnetMask
        if ($null -eq $decimalMask) { 
            Write-Verbose "Invalid subnet mask: $SubnetMask"
            return $null 
        }
        
        $binary = [Convert]::ToString($decimalMask, 2).PadLeft(32, '0')
        return ($binary -replace '0', '').Length
    }
    catch {
        Write-Verbose "Failed to convert subnet mask to CIDR: $_"
        return $null
    }
}

function Test-IPv4SubnetMask {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$IP
    )
    
    try {
        if (-not (Test-IPv4Address -IP $SubnetMask)) {
            return $false
        }
        
        $decimalMask = ConvertTo-IPv4Decimal $SubnetMask
        $binary = [Convert]::ToString($decimalMask, 2).PadLeft(32, '0')
        
        return -not ($binary -match '01')
    }
    catch {
        Write-Verbose "Failed to validate subnet mask: $_"
        return $false
    }
}

function Get-IPv4NetworkInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPAddress,
        
        [Parameter(Mandatory = $true)]
        [string]$SubnetMask,
        
        [Parameter()]
        [switch]$IncludeUsableRange
    )
    
    try {
        $ipDecimal = ConvertTo-IPv4Decimal $IPAddress
        $maskDecimal = ConvertTo-IPv4Decimal $SubnetMask
        $cidr = ConvertTo-IPv4CIDR $SubnetMask
        
        $networkDecimal = $ipDecimal -band $maskDecimal
        $wildcardDecimal = -bnot $maskDecimal
        $broadcastDecimal = $networkDecimal -bor $wildcardDecimal
        
        $networkAddress = ConvertTo-IPv4DottedDecimal $networkDecimal
        $broadcastAddress = ConvertTo-IPv4DottedDecimal $broadcastDecimal
        $wildcardMask = ConvertTo-IPv4DottedDecimal $wildcardDecimal
        
        $networkSize = $broadcastDecimal - $networkDecimal + 1
        
        $output = [PSCustomObject]@{
            IPAddress     = $IPAddress
            Mask          = $SubnetMask
            PrefixLength  = $cidr
            WildcardMask  = $wildcardMask
            NetworkAddress = $networkAddress
            BroadcastAddress = $broadcastAddress
            CIDR          = "$networkAddress/$cidr"
            TotalHosts    = $networkSize
        }
        
        if ($IncludeUsableRange) {
            if ($cidr -eq 32) {
                $usableRangeValue = "$networkAddress"
                $usableHostsCount = 1
            }
            elseif ($cidr -eq 31) {
                $usableRangeValue = "$networkAddress-$broadcastAddress"
                $usableHostsCount = 2
            }
            else {
                $firstHost = ConvertTo-IPv4DottedDecimal ($networkDecimal + 1)
                $lastHost = ConvertTo-IPv4DottedDecimal ($broadcastDecimal - 1)
                $usableRangeValue = "$firstHost-$lastHost"
                $usableHostsCount = $networkSize - 2
            }
            
            $output | Add-Member -MemberType NoteProperty -Name "UsableRange" -Value $usableRangeValue
            $output | Add-Member -MemberType NoteProperty -Name "UsableHosts" -Value $usableHostsCount
        }
        
        return $output
    }
    catch {
        Write-Error "Failed to calculate network information: $_"
        return $null
    }
}
