# Tests for Public/IPv6/Invoke-IPv6Calc.ps1

# Load the module
Import-Module "$PSScriptRoot\..\..\NetKit.psm1"

Describe "Invoke-IPv6Calc Tests" {

    Context "Invoke-IPv6Calc" {
        It "Calculates IPv6 network information from prefix string" {
            $result = Invoke-IPv6Calc -InputString "2001:db8::1/64"
            $result.NetworkAddress | Should -Be "2001:db8::"
            $result.LastAddress | Should -Be "2001:db8::ffff:ffff:ffff:ffff"
            $result.CompressedAddress | Should -Be "2001:db8::1"
            $result.ExpandedAddress | Should -Be "2001:0db8:0000:0000:0000:0000:0000:0001"
            $result.PrefixLength | Should -Be 64
        }

        It "Calculates IPv6 network information from IPv6 address and prefix length" {
            $result = Invoke-IPv6Calc -IPv6Address "2001:db8::1" -PrefixLength 48
            $result.NetworkAddress | Should -Be "2001:db8::"
            $result.LastAddress | Should -Be "2001:db8:ffff:ffff:ffff:ffff:ffff:ffff"
            $result.CompressedAddress | Should -Be "2001:db8::1"
            $result.ExpandedAddress | Should -Be "2001:0db8:0000:0000:0000:0000:0000:0001"
            $result.PrefixLength | Should -Be 48
        }
    }
}
