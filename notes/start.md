# Start

## Mission statement

How to setup OpenStack from unboxing to production

## Overview

CentOS 6.5 64-bit on all systems.
SaltStack for configuration.

Implement 4 node OpenStack cloud consisting of
* 1 utility node
* 1 controller node
* 1 network node
* 2 compute nodes

An additional utility node
 
### Installation overview:

* Utility Node Setup
* Environment Setup
* Common Setup
* Keystone Setup
* Glance Setup
* Neutron Setup
* Compute Setup 
* Gluster Setup 

The OpenStack services to be used 
* keystone
* glance
* neutron
* compute
* horizon

In addition
* celiometer

For storage use gluster
* gluster

## Allocate Hardware and Software

The controller, network and compute nodes are the same SuperMicro entry level server.

- [SUPERMICRO SYS-5018A-TN4 1U Rackmount Server Barebone FCBGA 1283 DDR3 1600/1333][1]
- [Kingston 8GB 204-Pin DDR3 SO-DIMM DDR3 1600 (PC3 12800) ECC Unbuffered Server Memory Model KVR16LSE11/8][2]
- [Intel 530 Series SSDSC2BW120A4K5 2.5" 120GB MLC][3]
- [Intel 530 Series SSDSC2BW240A4K5 2.5" 240GB SATA III MLC Internal Solid State Drive (SSD)][4]
- [TP-LINK JetStream TL-SG3216 Managed 16-Port Gigabit L2 Lite Managed Switch][5]
- [Intel EXPI9301CTBLK 10/ 100/ 1000Mbps PCI-Express Network Adapter][6]
- [CyberPower OR1500LCDRM1U 1500 VA 900 Watts 4 x 5-15R Battery & Surge 2 x 5-15R Surge-Only Outlets UPS][7]

### Utility

The utility node
* 1 x Intel i5-3337U Ivy Bridge 1.8GHz 
* 2 x 4GB DDR-1600
* 1 x Intel 240GB SSD
* 2 x Onboard NIC

### Controller

* 1 x Intel C2750 Atom 2.4GHz (8 cores)
* 4 x 8GB DDR-1600 ECC
* 1 x Intel 120GB SSD
* 4 x Onboard NIC
* 1 x Intel NIC

### Network

* 1 x Intel C2750 Atom 2.4 GHz (8 cores)
* 4 x 8GB DDR-1600 ECC
* 1 x Intel 120GB SSD
* 4 x Onboard NIC
* 1 x Intel NIC

### Compute 

The compute nodes will also run the GlusterFS filesystem.

* 1 x Intel C2750 Atom 2.4 GHz (8 cores)
* 4 x 8GB DDR-1600 ECC 
* 1 x Intel 120GB SSD
* 2 x Intel 240GB SSD
* 4 x Onboard NIC

Next: environment.txt


[1]: http://www.newegg.com/Product/Product.aspx?Item=N82E16816101836
[2]: http://www.newegg.com/Product/Product.aspx?Item=N82E16820239702
[3]: http://www.newegg.com/Product/Product.aspx?Item=20-167-177
[4]: http://www.newegg.com/Product/Product.aspx?Item=20-167-177
[5]: http://www.newegg.com/Product/Product.aspx?Item=N82E16833704093
[6]: http://www.newegg.com/Product/Product.aspx?Item=N82E16833106033
[7]: http://www.newegg.com/Product/Product.aspx?Item=N82E16842102095
