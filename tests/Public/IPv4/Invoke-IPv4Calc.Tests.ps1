# Tests for Public/IPv4/Invoke-IPv4Calc.ps1

# Load the module
Import-Module "$PSScriptRoot\..\..\NetKit.psm1"

Describe "Invoke-IPv4Calc Tests" {

    Context "Invoke-IPv4Calc" {
        It "Calculates subnet information from CIDR string" {
            $result = Invoke-IPv4Calc -InputString "192.168.1.1/24"
            $result.NetworkAddress | Should -Be "192.168.1.0"
            $result.BroadcastAddress | Should -Be "192.168.1.255"
            $result.Mask | Should -Be "255.255.255.0"
            $result.CIDR | Should -Be "192.168.1.0/24"
        }

        It "Calculates subnet information from IP and CIDR" {
            $result = Invoke-IPv4Calc -IPAddress "192.168.1.1" -CIDR 24
            $result.NetworkAddress | Should -Be "192.168.1.0"
            $result.BroadcastAddress | Should -Be "192.168.1.255"
            $result.Mask | Should -Be "255.255.255.0"
            $result.CIDR | Should -Be "192.168.1.0/24"
        }

        It "Calculates subnet information from IP and subnet mask" {
            $result = Invoke-IPv4Calc -IPAddress "192.168.1.1" -SubnetMask "255.255.255.0"
            $result.NetworkAddress | Should -Be "192.168.1.0"
            $result.BroadcastAddress | Should -Be "192.168.1.255"
            $result.Mask | Should -Be "255.255.255.0"
            $result.CIDR | Should -Be "192.168.1.0/24"
        }

        It "Calculates subnet information from network and broadcast addresses" {
            $result = Invoke-IPv4Calc -NetworkAddress "192.168.1.0" -BroadcastAddress "192.168.1.255"
            $result.NetworkAddress | Should -Be "192.168.1.0"
            $result.BroadcastAddress | Should -Be "192.168.1.255"
            $result.Mask | Should -Be "255.255.255.0"
            $result.CIDR | Should -Be "192.168.1.0/24"
        }
    }

    Context "New-BasicSubnet" {
        It "Divides network into equal subnets" {
            $result = New-BasicSubnet -NetworkCIDR "192.168.0.0/24" -NumberOfSubnets 4
            $result.Count | Should -Be 4
            $result[0].Subnet | Should -Be "192.168.0.0/26"
            $result[1].Subnet | Should -Be "192.168.0.64/26"
            $result[2].Subnet | Should -Be "192.168.0.128/26"
            $result[3].Subnet | Should -Be "192.168.0.192/26"
        }

        It "Divides network into subnets with minimum hosts" {
            $result = New-BasicSubnet -NetworkCIDR "192.168.0.0/24" -HostsPerSubnet 50
            $result.Count | Should -Be 4
            $result[0].Subnet | Should -Be "192.168.0.0/26"
            $result[1].Subnet | Should -Be "192.168.0.64/26"
            $result[2].Subnet | Should -Be "192.168.0.128/26"
            $result[3].Subnet | Should -Be "192.168.0.192/26"
        }
    }

    Context "New-VLSMSubnet" {
        It "Creates VLSM subnets" {
            $result = New-VLSMSubnet -NetworkCIDR "192.168.0.0/24" -HostsPerSubnet 100, 50, 25, 10
            $result.Count | Should -Be 4
            $result[0].Subnet | Should -Be "192.168.0.0/25"
            $result[1].Subnet | Should -Be "192.168.0.128/26"
            $result[2].Subnet | Should -Be "192.168.0.192/27"
            $result[3].Subnet | Should -Be "192.168.0.224/28"
        }

        It "Creates named VLSM subnets" {
            $result = New-VLSMSubnet -NetworkCIDR "192.168.0.0/24" -HostsPerSubnet 100, 50, 25, 10 -SubnetNames "HQ", "Branch1", "Branch2", "Guest"
            $result.Count | Should -Be 4
            $result[0].Name | Should -Be "HQ"
            $result[1].Name | Should -Be "Branch1"
            $result[2].Name | Should -Be "Branch2"
            $result[3].Name | Should -Be "Guest"
        }
    }
}
