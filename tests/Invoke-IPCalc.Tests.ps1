# Tests for Invoke-IPCalc.ps1

# Load the module
Import-Module "$PSScriptRoot\..\NetKit.psm1"

Describe "Invoke-IPCalc Tests" {

    Context "Test-ValidIPAddress" {
        It "Validates a correct IP address" {
            $result = Test-ValidIPAddress -IP "192.168.1.1"
            $result | Should -Be $true
        }

        It "Invalidates an incorrect IP address" {
            $result = Test-ValidIPAddress -IP "999.999.999.999"
            $result | Should -Be $false
        }
    }

    Context "ConvertTo-DecimalIP" {
        It "Converts IP address to decimal" {
            $result = ConvertTo-DecimalIP -IP "192.168.1.1"
            $result | Should -Be 3232235777
        }
    }

    Context "ConvertTo-DottedIP" {
        It "Converts decimal to IP address" {
            $result = ConvertTo-DottedIP -IPDecimal 3232235777
            $result | Should -Be "192.168.1.1"
        }
    }

    Context "ConvertTo-SubnetMask" {
        It "Converts CIDR to subnet mask" {
            $result = ConvertTo-SubnetMask -PrefixLength 24
            $result | Should -Be "255.255.255.0"
        }
    }

    Context "ConvertTo-CIDR" {
        It "Converts subnet mask to CIDR" {
            $result = ConvertTo-CIDR -SubnetMask "255.255.255.0"
            $result | Should -Be 24
        }
    }
}
