# Tests for Private/IPv4Helpers.ps1

# Load the module
Import-Module "$PSScriptRoot\..\..\NetKit.psm1"

Describe "IPv4Helpers Tests" {

    Context "Test-IPv4Address" {
        It "Validates a correct IPv4 address" {
            $result = Test-IPv4Address -IP "192.168.1.1"
            $result | Should -Be $true
        }

        It "Invalidates an incorrect IPv4 address" {
            $result = Test-IPv4Address -IP "999.999.999.999"
            $result | Should -Be $false
        }
    }

    Context "ConvertTo-IPv4Decimal" {
        It "Converts IPv4 address to decimal" {
            $result = ConvertTo-IPv4Decimal -IP "192.168.1.1"
            $result | Should -Be 3232235777
        }
    }

    Context "ConvertTo-IPv4DottedDecimal" {
        It "Converts decimal to IPv4 address" {
            $result = ConvertTo-IPv4DottedDecimal -IPDecimal 3232235777
            $result | Should -Be "192.168.1.1"
        }
    }

    Context "ConvertTo-IPv4SubnetMask" {
        It "Converts CIDR to IPv4 subnet mask" {
            $result = ConvertTo-IPv4SubnetMask -PrefixLength 24
            $result | Should -Be "255.255.255.0"
        }
    }

    Context "ConvertTo-IPv4CIDR" {
        It "Converts IPv4 subnet mask to CIDR" {
            $result = ConvertTo-IPv4CIDR -SubnetMask "255.255.255.0"
            $result | Should -Be 24
        }
    }
}
