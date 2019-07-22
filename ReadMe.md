# System tricks

## static-ipsec 

Linux l2tp over ipsec with static keys, requires no additions daemons installed except linux kernel 3+. 

```
LOCAL/REMOTE - ipv4/ipv6 addresses. 
LPORT/RPORT - ports used for incoming / outgoing udp-traffic encapsulating l2tp session. 
```

Keys can be generated using
```
dd if=/dev/urandom bs=1 count=32 | xxd -p -c 32 
```

As the keys are static, they recommend to change keys after (2^key_bits)/2 block encrypted.  


## multi-instance-mysql 

Running multi instances of mysql under systemd within sandboxes, keeping system paths/configs untouched. 
Preparations: 

```
mkdir -p /srv/mysql/mysql-one/data /srv/mysql/mysql-one/binlog
mkdir -p /srv/mysql/mysql-two/data /srv/mysql/mysql-two/binlog

cp my.cnf /srv/mysql/mysql-one/ 
cp my.cnf /srv/mysql/mysql-two/ 

# Edit each my.cnf to avoid bind ports overcrossing. 

mysql_install_db --defaults-file=/srv/mysql/mysql-one/my.cnf --user=mysql
mysql_install_db --defaults-file=/srv/mysql/mysql-two/my.cnf --user=mysql

cp mysql@.service /etc/systemd/systemd/
systemctl daemon-reload 
systemctl enable mysql@one ; systemctl start mysql@one 
systemctl enable mysql@two ; systemctl start mysql@two 
```

## lxc-dev-cloud

A first approach to create lightweight, fast and flexible environment for multi-host development.  Prerequisites: 
 - build on top of vanila lxc
 - this partucular example runs on Debian 8, with minor changes it will work on any other distro. 
 - containers run Centos 7, with minor changes in create.sh script will run any other distro. 

This example assumes: 
 - ssh root access to host-node enabled; 
 - the host-node has external static ip-address 9.8.7.6; 
 - may or may not have IPV6 сonnectivity; 
 - internal network is 10.0.0.0/24; 
 - internal domain is dev.cloud;  
 - internal host-node's name is host01.dev.cloud; 
 - containers have access to outside network through SNAT;
 - external resolving forwarded to Google Public DNS; 

Preparations: 

```
apt-get update 
apt-get install bridge-utils uuid lxc lxctl dnsmasq 
```

Tying all together: 

- setup dummy bridge interface inside0, as shown in etc/network/interfaces.d/inside0 
- setup iptables rules for NAT and add iptables in network start process ( etc/iptables.rules / etc/network/if-up.d/iptables ) 
- enable ipv4 forwarding via sysctl ( etc/sysctl.d/99-forwarding.conf ) 
- setup dnsmasq as DHCP/internal DNS/DNS forwarder ( etc/dnsmasq.conf ) 
- add client_ssh_config to your local ~/.ssh/config 
- create containers: 
``` 
cd bin 
./create testhost 
```

Now you should see something like this: 
```
root@host01 ~ # lxc-ls -f
NAME       STATE   AUTOSTART GROUPS IPV4        IPV6
testhost   RUNNING 1         -      10.0.0.10   -
root@host01 ~ #
```

Note, that default centos7 image, available from lxc repository, comes without sshd and with no users created for security reasons. 
So you have to connect to container via lxc-attach: 
```
root@host01 ~ # lxc-attach -n testhost
[root@testhost ~]# yum install openssh-server 

< installation and user creation goes here > 

[root@testhost ~]# exit 
root@host01 ~ #
``` 

Then, just ssh into container from outside: 

```
ssh root@testhost.dev.cloud 
```

Advantages: 
 - dnsmasq takes all the job of holding internal LAN state; the only meaningful option is containter name set in create.sh script. 
 - it's easy to scale this setup to any number of internal LANs.
 - it's easy to scale this setup upon several host-nodes using kernel-space l2tp tunnels, binded to internal bridge. 
 - lxc containers share resources more effectively, than true virtualisation. 

Disadvantages: 
 - a lot of. 


 
## netlab

lxc-based lightweight environment for modelling networks with complex routing scheme. Host system is debian 9, should also run under other distros (not tested as for now). 

Mandatory requirements: 
 - lxc 
 - bridge-utils
 - graphviz 
 - frr 

Optional requirements: 
 - lldpd 
 - libgraph-easy-perl
 - tmux 

Required packages should be installed into host system, containers inherrit software from host root fs. 
By default, frr is ruinning with only BGP enabled. 
  
Usage: 
network.dot graph describes desired topology. `lab` script creates/destroys environment according to described one in network.dot: 

```
# ./lab start
                      ┌────────────┐
  ┌────────────────── │ management │
  │                   └────────────┘
  │                     │
  │                     │
  │                     │
  │                   ┌────────────┐
  │                   │  router01  │
  │                   └────────────┘
  │                     │
  │                     │
  │                     │
  │  ┌──────────┐     ┌────────────────────────┐     ┌──────────┐
  │  │ server02 │ ─── │        service         │ ─── │ server03 │
  │  └──────────┘     └────────────────────────┘     └──────────┘
  │                     │             │
  │                     │             │
  │                     │             │
  │                   ┌────────────┐┌──────────┐
  └────────────────── │  router02  ││ server01 │
                      └────────────┘└──────────┘
NAME     STATE   AUTOSTART GROUPS IPV4 IPV6
router01 RUNNING 1         -      -    -
router02 RUNNING 1         -      -    -
server01 RUNNING 1         -      -    -
server02 RUNNING 1         -      -    -
server03 RUNNING 1         -      -    -

# lxc-attach -n router01
root@router01 / # lldpctl 
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    management, via: LLDP, RID: 1, Time: 0 day, 00:02:10
  Chassis:
    ChassisID:    mac 6e:76:46:48:03:41
    SysName:      router02
    SysDescr:     Debian GNU/Linux 9 (stretch) Linux 4.9.0-6-amd64 #1 SMP Debian 4.9.82-1+deb9u3 (2018-03-02) x86_64
    TTL:          15
    MgmtIP:       172.30.1.2
    MgmtIP:       fe80::6c76:46ff:fe48:341
    Capability:   Bridge, off
    Capability:   Router, on
    Capability:   Wlan, off
    Capability:   Station, on
  Port:
    PortID:       mac 6e:76:46:48:03:41
    PortDescr:    management
    PMD autoneg:  supported: no, enabled: no
      MAU oper type: 10GigBaseCX4 - X copper over 8 pair 100-Ohm balanced cable
-------------------------------------------------------------------------------
Interface:    service, via: LLDP, RID: 1, Time: 0 day, 00:02:10
  Chassis:
    ChassisID:    mac 6e:76:46:48:03:41
    SysName:      router02
    SysDescr:     Debian GNU/Linux 9 (stretch) Linux 4.9.0-6-amd64 #1 SMP Debian 4.9.82-1+deb9u3 (2018-03-02) x86_64
    TTL:          15
    MgmtIP:       172.30.1.2
    MgmtIP:       fe80::6c76:46ff:fe48:341
    Capability:   Bridge, off
    Capability:   Router, on
    Capability:   Wlan, off
    Capability:   Station, on
  Port:
    PortID:       mac 1a:24:9e:36:55:b1
    PortDescr:    service
    PMD autoneg:  supported: no, enabled: no
      MAU oper type: 10GigBaseCX4 - X copper over 8 pair 100-Ohm balanced cable
-------------------------------------------------------------------------------
[ ... ] 

root@router01 / # vtysh

Hello, this is FRRouting (version 7.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router01# sh run
Building configuration...

Current configuration:
!
frr version 7.1
frr defaults traditional
hostname router01
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface management
 ip address 172.30.1.1/24
!
line vty
!
end
router01# exit
root@router01 / # exit
 # ./lab stop
NAME     STATE   AUTOSTART GROUPS IPV4 IPV6
#
```
