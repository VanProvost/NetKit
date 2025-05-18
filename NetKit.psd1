@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'NetKit.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'c89a7b3e-94f5-4a78-9ec3-32d3b6c4c86f'
    
    # Author of this module
    Author = 'Van Provost'
    
    # Company or vendor of this module
    CompanyName = 'VanProvost'
    
    # Copyright statement for this module
    Copyright = '(c) 2023 Van Provost. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'A comprehensive toolkit for network calculations including IPv4 and IPv6 subnet calculations, basic subnetting, and VLSM subnetting.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Invoke-IPv4Calc',
        'Invoke-IPv6Calc',
        'New-BasicSubnet',
        'New-VLSMSubnet'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        'ipc4',
        'ipc6'
    )
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for PowerShell Gallery discoverability
            Tags = @('Network', 'IPv4', 'IPv6', 'Subnetting', 'VLSM')
            
            # License URI for this module
            LicenseUri = 'https://opensource.org/licenses/MIT'
            
            # Project URI for this module
            ProjectUri = 'https://github.com/VanProvost/NetKit'
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of NetKit module with IPv4, IPv6, basic subnetting and VLSM subnetting capabilities.'
        }
    }
}