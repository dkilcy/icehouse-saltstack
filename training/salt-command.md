### Salt Command - Objectives

- Executing Salt
- Targets and the matcher system
- Salt functions
- Passing arguments
- Built-in documentation
- Core functions

The `salt` command is used to send remote exec commands out to the minions from the master. 

    salt <target> <module.function> <arguments>

* Command Options
* Target Specification
* Function to call
* Function Arguments

Example

    salt '*' test.ping
    
Turn debug on

    salt -l debug '*' test.ping
    salt --log-level=debug '*' test.ping
    
### Targets

- Central to how Salt works
- Many options
- Flexible

Commands sent out via Salt are targeted to execute only on specified minions.  The targeting system allows for the specific minions to be targeted in very granular ways  and to target them as simply and easily as possible.

The target system is used in many parts of Salt and an understanding of it is central to using the Salt system as a whole.

Ways to Target

Matching by `id`

- Use filesystem globs by default
- Can use pure regex
- Pass explicit set of minions

Salt organizes minions based on the minion id. The id is erither derived from the hostname or can be statically set inside the minion config file.

By default salt uses filesystem globs to match minion ids.

    salt '*' test.ping
    salt '*.mgmt' test.ping
    salt 'compute-0[1-5].mgmt' test.ping

Regular expressions can be used to match minions

    salt -E 'compute-02.(mgmt|vm)` test.ping

List Matching

    salt -L 'compute-01.mgmt,compute-02.mgmt' test.ping
    
Matching by IP address or network and subnet

    salt -S '10.0.0.32' test.ping
    salt -S '10.0.0.0/24' test.ping
    
### Grains

- static system data
- read in when the minion starts
- can be used for targeting
- statically set in the minion config
- globs or regex

Grains are bits of static system data that would not change in the event of a reboot.  They are static variables held in memory.

Grains cover data such as information on the OS, kernel, hardware and similar data.

Grains are what is generally used to determine things like what package manager to use or if the init system is powered  by upstart or systemd.

Grains can be any data structure: list, string, int, dict

    $ salt compute-02.mgmt grains.get num_cpus
    compute-02.mgmt:
        8
    $  salt compute-02.mgmt grains.item num_cpus
    compute-02.mgmt:
        num_cpus: 8

Grains can be used to target systems.  

    $ salt -G 'os:CentOS' grains.items
    compute-02.mgmt:
        biosreleasedate: 11/06/2013
         ...
        zmqversion: 3.2.4
    $ salt -G 'cpuarch:x86_64' grains.item num_cpus
    compute-02.mgmt:
        num_cpus: 8
    
By default grains are matched with globs
Regular expression can also be used to match with `--grain-pcre`

    salt --grain-pcre 'os:Cen.*' test.ping
    
Grains can be set in the minion configuration file.

    grains:
      roles:
        - compute
        - glusterfs
      deployment: datacenter4
      cabinet: 13
      cab_u: 14-15
      
Grains can be set in the /etc/salt/grains file
    
    roles:
      - compute
      - glusterfs
    deployment: datacenter4
    cabinet: 13
    cab_u: 14-15
      
Grains can be set using the grains.setval function. It adds it to the /etc/salt/grains file on the minion.

    $ salt compute-02.mgmt grains.setval roles '[compute, glusterfs]'
    compute-02.mgmt:
        roles:
            compute
            glusterfs
    $ salt -G 'roles:compute' test.ping
    compute-02.mgmt:
        True
    $ salt -G 'roles:compute' cmd.run 'cat /etc/salt/grains'
    compute-02.mgmt:
        roles:
        - compute
        - glusterfs

Grains can be set in the cloud profile for salt-cloud


### Pillar

- Master-side minion-specific data
- Can hold arbitrary data
- Can be used for matching
 
Pillar is a generic source of global data passed to minions.  
Pillar data can be used for minion configuration or to store sensitive data.

    salt -I 'key:value' pillar.data

### Compound Matching

- Use logic in matching
- Have multiple targets called together
- Nodegroups use compound targets
- Joined with `and` `or` `not` operators

Compound targets merge together many matchers to determine the target.

    salt -C 'G@os:CentOS and *.mgmt' test.ping

Match types:

    G   Grains glob match
    E   PCRE minion id match
    P   Grains PCRE match
    L   List of minions
    I   Pillar glob match
    R   Range cluster match
    S   IP/subnet match
    
### Nodegroups

Nodegroups allow for a group to be specified in the master config file
They are always specified using compound matchers 

    nodegroups:
      group1: 'L@foo.example.com,bar.example.com and baz.example.com'
      group2: 'G@os:CentOS'
      
    salt -N group1 test.ping  
     
### Functions

- salt calls python functions on the minion
- functions are housed in Execution Modules
- modules are automatically loaded for the platform
- 'pkg' uses the right module for the platform
- 
### Automatic Platform Detection

Using grains salt modules can automatically reroute to platform specific.
For example the pkg module automatically routes to the systems package manager module.

### Self-Documenting Execution Modules

    salt '*' sys.doc | less
    salt '*' sys.doc test.ping
    salt 'master' sys.list_modules
    man 7 salt
     
### Core Functions

- Command exec
- Package mgmt
- Network data
- Test interface
- User management

The `cmd` module is used to shell out to the command line and execute:
    
    $ salt compute-02.mgmt cmd.run 'ps -ef | grep salt'
    compute-02.mgmt:
    root      9227     1  0 21:28 ?        00:00:00 /usr/bin/python /usr/bin/salt-minion -d
    root      9228  9227  0 21:28 ?        00:00:00 /bin/sh -c ps -ef | grep salt
    root      9230  9228  0 21:28 ?        00:00:00 grep salt
    root     24991     1  0 Sep02 ?        00:01:32 /usr/bin/python /usr/bin/salt-minion -d
    $ salt compute-02.mgmt cmd.script 
    $ salt compute-02.mgmt cmd.exec_code 
    
    
### Package Management

The `pkg` module comes with a numberof standard functions that map to separate platforms

    salt 'compute-02.mgmt' pkg.list_pkgs

##### Network Data

    $ salt '*' network.ip_addrs
    compute-02.mgmt:
        - 10.0.0.32
        - 10.0.1.32


##### Test 

    $ salt '*' test.versions_report
    compute-02.mgmt:
               Salt: 2014.1.5
             Python: 2.6.6 (r266:84292, Jan 22 2014, 09:42:36)
             Jinja2: 2.7.2
           M2Crypto: 0.20.2
     msgpack-python: 0.1.13
       msgpack-pure: Not Installed
           pycrypto: 2.6.1
             PyYAML: 3.10
              PyZMQ: 2.2.0.1
                ZMQ: 3.2.4
    $ salt '*' test.versions_report --out=json
    {
        "compute-02.mgmt": "           Salt: 2014.1.5\n         Python: 2.6.6 (r266:84292, Jan 22 2014, 09:42:36)\n         Jinja2: 2.7.2\n       M2Crypto: 0.20.2\n msgpack-python: 0.1.13\n   msgpack-pure: Not Installed\n       pycrypto: 2.6.1\n         PyYAML: 3.10\n          PyZMQ: 2.2.0.1\n            ZMQ: 3.2.4"
    }

##### User

