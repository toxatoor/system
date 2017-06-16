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


 
