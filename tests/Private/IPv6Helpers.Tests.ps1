# Tests for Private/IPv6Helpers.ps1

# Load the module
Import-Module "$PSScriptRoot\..\..\NetKit.psm1"

Describe "IPv6Helpers Tests" {

    Context "Test-IPv6Address" {
        It "Validates a correct IPv6 address" {
            $result = Test-IPv6Address -IP "2001:db8::1"
            $result | Should -Be $true
        }

        It "Invalidates an incorrect IPv6 address" {
            $result = Test-IPv6Address -IP "2001:db8::g"
            $result | Should -Be $false
        }
    }

    Context "ConvertTo-IPv6Compressed" {
        It "Converts IPv6 address to compressed format" {
            $result = ConvertTo-IPv6Compressed -IPv6Address "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
            $result | Should -Be "2001:db8:85a3::8a2e:370:7334"
        }
    }

    Context "ConvertTo-IPv6Expanded" {
        It "Converts IPv6 address to expanded format" {
            $result = ConvertTo-IPv6Expanded -IPv6Address "2001:db8:85a3::8a2e:370:7334"
            $result | Should -Be "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        }
    }

    Context "Get-IPv6NetworkInfo" {
        It "Calculates IPv6 network information" {
            $result = Get-IPv6NetworkInfo -IPv6Address "2001:db8::" -PrefixLength 64
            $result.NetworkAddress | Should -Be "2001:db8::"
            $result.LastAddress | Should -Be "2001:db8::ffff:ffff:ffff:ffff"
            $result.TotalAddresses | Should -Be "18,446,744,073,709,551,616"
        }
    }
}
