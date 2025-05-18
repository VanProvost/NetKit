# NetKit

## Overview

NetKit is a comprehensive toolkit for network calculations, including IPv4 and IPv6 subnet calculations, basic subnetting, and VLSM subnetting. It provides a set of PowerShell functions to help network administrators and engineers perform various network-related tasks.

## Features

- IPv4 and IPv6 subnet calculations
- Basic subnetting
- Variable Length Subnet Mask (VLSM) subnetting
- Detailed subnet information including subnet mask, CIDR notation, wildcard mask, network address, and broadcast address
- Usable IP range calculation

## Installation

To install NetKit, you can clone the repository and import the module into your PowerShell session:

```sh
git clone https://github.com/VanProvost/NetKit.git
Import-Module ./NetKit/NetKit.psd1
```

## Usage

### IPv4 Subnet Calculation

To calculate IPv4 subnet information, use the `Invoke-IPv4Calc` function. You can provide different input formats such as IP address with CIDR notation, IP address and subnet mask, or network address and broadcast address.

#### Examples

```sh
# Calculate subnet information using IP address and CIDR notation
Invoke-IPv4Calc 192.168.1.1/24

# Calculate subnet information using IP address and CIDR prefix
Invoke-IPv4Calc -IPAddress 192.168.1.1 -CIDR 24

# Calculate subnet information using IP address and subnet mask
Invoke-IPv4Calc -IPAddress 10.0.0.15 -SubnetMask 255.255.255.0 -UsableRange

# Calculate subnet information using network and broadcast addresses
Invoke-IPv4Calc -NetworkAddress 192.168.1.0 -BroadcastAddress 192.168.1.255
```

### Basic Subnetting

To divide an IPv4 network into equal-sized subnets, use the `New-BasicSubnet` function. You can specify the number of subnets or the minimum number of hosts required in each subnet.

#### Examples

```sh
# Divide the 192.168.0.0/24 network into 4 equal subnets
New-BasicSubnet -NetworkCIDR 192.168.0.0/24 -NumberOfSubnets 4

# Divide the 10.0.0.0/16 network into subnets that can each accommodate at least 1000 hosts
New-BasicSubnet -NetworkCIDR 10.0.0.0/16 -HostsPerSubnet 1000

# Divide the 192.168.0.0/24 network into 8 equal subnets and display usable IP ranges
New-BasicSubnet 192.168.0.0/24 8 -IncludeUsableRange
```

### VLSM Subnetting

To create subnets of different sizes using Variable Length Subnet Mask (VLSM), use the `New-VLSMSubnet` function. You can specify the required number of hosts for each subnet and optionally assign names to each subnet.

#### Examples

```sh
# Create four subnets from 192.168.0.0/24 with enough space for 100, 50, 25, and 10 hosts respectively
New-VLSMSubnet -NetworkCIDR 192.168.0.0/24 -HostsPerSubnet 100,50,25,10

# Create four named subnets with the specified host requirements
New-VLSMSubnet -NetworkCIDR 10.0.0.0/16 -HostsPerSubnet 1000,500,250,100 -SubnetNames "HQ","Branch1","Branch2","Guest"

# Create three subnets with usable IP ranges displayed
New-VLSMSubnet 192.168.0.0/24 @(50,20,10) -IncludeUsableRange
```

### IPv6 Subnet Calculation

To calculate IPv6 subnet information, use the `Invoke-IPv6Calc` function. You can provide an IPv6 address with prefix notation or an IPv6 address and prefix length.

#### Examples

```sh
# Calculate network information for the given IPv6 address and prefix
Invoke-IPv6Calc 2001:db8::1/64

# Calculate network information using the IPv6 address and prefix length
Invoke-IPv6Calc -IPv6Address 2001:db8::1 -PrefixLength 48
```

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
