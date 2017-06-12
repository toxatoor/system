# System tricks

## static-ipsec 

Linux l2tp over ipsec with static keys, requires no additions daemons installed except linux kernel 3+ 
LOCAL/REMOTE - ipv4/ipv6 addresses 
LPORT/RPORT - ports used for incoming / outgoing udp-traffic encapsulating l2tp session 

Keys can be generated using
```
dd if=/dev/urandom bs=1 count=32 | xxd -p -c 32 
```

As the keys are static, they recommend to change keys after (2^key_bits)/2 block encrypted.  

