# icehouse-saltstack

CentOS 6.5 version
New projct is juno-saltstack

## Mission statement

Setup an OpenStack private cloud multi-node architecture with OpenStack Neutron Networking from unboxing to production.

SaltStack will be used to automate the deployment of the controller, network and multiple compute nodes.

The first phase of the project will bootstrap the initial multi-node architecture.

Additional phases will include:
- Redundant controller and network nodes for HA/disaster recovery and performance
- Swift and Cinder Object/Block storage
- Celiometer and Horizon 
- Ethernet bonding

I started this project because of the lack of information about Neutron networking and setting up OpenStack in real production environments.  Sure you can use "devstack" to do the work for you, but it does not mimic a real production setup.  In addition I wanted to install and configure each of the components manually to get a better understanding of the ecosystem, and to do it in an automated and reproducable way.  By authoring my own Salt formulas for deployment the ultimate goal is to be able to deploy an entire OpenStack ecosystem ranging from 3 to 3000 systems with a single Salt highstate command.

To sum it up, I view "devstack" as reading a book about math.  You do not learn math unless you actually work the problems.  Thus the catalyst for this project.

## Overview

* OpenStack Icehouse release
* CentOS 6.5 64-bit on all systems.
* Kickstart scripts that boot from the utility node via HTTP for bare-metal configuration, no manual installs here.
* SaltStack for configuration
* CentOS repository mirror on the utility nodes.\

The first phase will implement 4 node OpenStack cloud consisting of:

* 1 controller node
* 1 network node
* 2 compute nodes

To support the environment there are:

* 2 utility nodes 
* 2 TP-Link L2 managed switches for redundancy.
* 2 CyberPower OR1500 UPS

With the exception of the utility nodes, all equipment is rack-mounted.

2 additional nodes will be added later for controller and network node redundancy/peformance.

 
### Installation overview:

First phase:

* Utility Node Setup
* Environment Setup
* Common Setup
* Keystone Setup
* Glance Setup
* Neutron Setup
* Compute Setup 

Second phase:

* Celiometer
* Horizon

For storage:

* Swift object storage
* Cinder block storage

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
* 4 x 8GB DDR-1600 ECC memory
* 1 x Intel 120GB SSD drive
* 4 x Onboard NIC
* 1 x Intel NIC

### Network

* 1 x Intel C2750 Atom 2.4 GHz (8 cores)
* 4 x 8GB DDR-1600 ECC memory
* 1 x Intel 120GB SSD drive
* 4 x Onboard NIC
* 1 x Intel NIC

### Compute 

The compute nodes will also run Cinder and Swift components.

* 1 x Intel C2750 Atom 2.4 GHz (8 cores)
* 4 x 8GB DDR-1600 ECC 
* 1 x Intel 120GB SSD
* 2 x Intel 240GB SSD
* 4 x Onboard NIC


#### Network topology

There are 3 networks.

Network                     | Domain	
--------------------------- | ------
OpenStack Internal Network  | .mgmt
Public Network              | .pub
VM Traffic Network          | .vm

#### IP Address and Ethernet assignments

For simplicity,
eth0 handles internal network
eth1 handles public network
eth2 handles VM network

Later on eth3 and eth4 will be used for bonding to increase network performance.

Node           | eth0          | eth1           | eth2           | eth3           | eth4
-------------- | ------------- | -------------- | -------------- | -------------- | -------------- |
workstation-01 | 10.0.0.5      | 192.168.1.5    |                |                |                |
workstation-02 | 10.0.0.6      | 192.168.1.6    |                |                |                |
controller-01  | 10.0.0.11     | 192.168.1.11   |                |                |                |
network-01     | 10.0.0.21     | External       | 10.0.1.21      |                |                |
compute-01     | 10.0.0.31     |                | 10.0.1.31      |                |                |
compute-02     | 10.0.0.32     |                | 10.0.1.32      |                |                |


[1]: http://www.newegg.com/Product/Product.aspx?Item=N82E16816101836
[2]: http://www.newegg.com/Product/Product.aspx?Item=N82E16820239702
[3]: http://www.newegg.com/Product/Product.aspx?Item=20-167-177
[4]: http://www.newegg.com/Product/Product.aspx?Item=20-167-177
[5]: http://www.newegg.com/Product/Product.aspx?Item=N82E16833704093
[6]: http://www.newegg.com/Product/Product.aspx?Item=N82E16833106033
[7]: http://www.newegg.com/Product/Product.aspx?Item=N82E16842102095
