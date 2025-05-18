# NetKit - A Comprehensive Network Calculation Toolkit
# Module script file that loads all functions

# Get the directory where this script is located
$ModulePath = $PSScriptRoot

# Initialize timer for performance tracking
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$moduleLoadingErrors = 0

# First ensure private directory exists
if (-not (Test-Path -Path "$ModulePath\Private" -PathType Container)) {
    Write-Warning "Private module directory not found. Creating directory structure."
    try {
        $null = New-Item -Path "$ModulePath\Private" -ItemType Directory -Force
    }
    catch {
        Write-Error "Failed to create Private directory: $_"
    }
}

# Ensure public directory exists
if (-not (Test-Path -Path "$ModulePath\Public" -PathType Container)) {
    Write-Warning "Public module directory not found. Creating directory structure."
    try {
        $null = New-Item -Path "$ModulePath\Public" -ItemType Directory -Force
    }
    catch {
        Write-Error "Failed to create Public directory: $_"
    }
}

# Import Private/Helper Functions (not exported to module users)
$privatePath = "$ModulePath\Private"
if (Test-Path -Path $privatePath) {
    $PrivateFunctions = @(Get-ChildItem -Path $privatePath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
    
    # Sort by name for predictable loading order
    $PrivateFunctions = $PrivateFunctions | Sort-Object -Property FullName
    
    Write-Verbose "Found $($PrivateFunctions.Count) private functions to import"
    
    foreach ($function in $PrivateFunctions) {
        try {
            Write-Verbose "Importing private function: $($function.BaseName)"
            . $function.FullName
        }
        catch {
            $moduleLoadingErrors++
            Write-Error "Failed to import private function $($function.FullName): $_"
        }
    }
}
else {
    Write-Warning "Private directory not found at path: $privatePath"
}

# Import Public Functions (exported to module users)
$publicPath = "$ModulePath\Public"
if (Test-Path -Path $publicPath) {
    $PublicFunctions = @(Get-ChildItem -Path $publicPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
    
    # Sort by name for predictable loading order
    $PublicFunctions = $PublicFunctions | Sort-Object -Property FullName
    
    Write-Verbose "Found $($PublicFunctions.Count) public functions to import"
    
    # Check if core module functions were found
    $coreFoundIPv4 = $false
    $coreFoundIPv6 = $false
    
    foreach ($function in $PublicFunctions) {
        try {
            Write-Verbose "Importing public function: $($function.BaseName)"
            . $function.FullName
            
            # Export the function based on filename (must match function name)
            $functionName = $function.BaseName
            Export-ModuleMember -Function $functionName
            
            # Track if core functions are found
            if ($functionName -eq 'Invoke-IPv4Calc') { $coreFoundIPv4 = $true }
            if ($functionName -eq 'Invoke-IPv6Calc') { $coreFoundIPv6 = $true }
        }
        catch {
            $moduleLoadingErrors++
            Write-Error "Failed to import public function $($function.FullName): $_"
        }
    }
    
    # Check core functionality
    if (-not $coreFoundIPv4 -or -not $coreFoundIPv6) {
        Write-Warning "One or more core module functions were not found. The module may not function correctly."
    }
}
else {
    Write-Warning "Public directory not found at path: $publicPath"
}

# Define and export aliases if core functions were imported
if (Get-Command -Name 'Invoke-IPv4Calc' -ErrorAction SilentlyContinue) {
    New-Alias -Name 'ipc4' -Value 'Invoke-IPv4Calc' -Force
    Export-ModuleMember -Alias 'ipc4'
}
else {
    Write-Warning "Invoke-IPv4Calc function not found, alias 'ipc4' not created."
}

if (Get-Command -Name 'Invoke-IPv6Calc' -ErrorAction SilentlyContinue) {
    New-Alias -Name 'ipc6' -Value 'Invoke-IPv6Calc' -Force 
    Export-ModuleMember -Alias 'ipc6'
}
else {
    Write-Warning "Invoke-IPv6Calc function not found, alias 'ipc6' not created."
}

# Report module loading performance
$stopwatch.Stop()
$loadTime = $stopwatch.ElapsedMilliseconds
Write-Verbose "NetKit module loaded in $loadTime ms with $moduleLoadingErrors errors"