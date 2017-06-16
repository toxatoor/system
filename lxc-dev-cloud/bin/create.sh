#!/bin/bash

name=$1

lxc-create -n $name -f config -t download -- -d centos -r 7 -a amd64
mac=`uuid -d $(uuid) | grep 'node:'   | awk '{print $2}' | awk -F':' '{print "aa:bb:"$4":"$1":"$2":"$3}'`
echo -ne "lxc.network.hwaddr = $mac\n"  >> /var/lib/lxc/$name/config 
lxc-start -d -n $name 
lxc-attach -n $name -- /bin/ln -s /usr/lib/systemd/system/halt.target /etc/systemd/system/sigpwr.target && systemctl daemon-reload
