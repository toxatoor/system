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

