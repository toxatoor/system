#!/bin/bash

. vars 

/sbin/modprobe l2tp_eth

/sbin/ip xfrm state add src $REMOTE dst $LOCAL proto esp spi $RSPI reqid $RREQ mode transport auth sha256 $RKEYAUTH enc aes $RKEYENC sel src $REMOTE dst $LOCAL

/sbin/ip xfrm state add src $LOCAL dst $REMOTE proto esp spi $LSPI reqid $RREQ mode transport auth sha256 $LKEYAUTH enc aes $LKEYENC sel src $LOCAL dst $REMOTE

/sbin/ip xfrm policy add src $REMOTE dst $LOCAL proto udp sport $RPORT dport $LPORT dir out tmpl src $REMOTE dst $LOCAL proto esp reqid $RREQ mode transport
/sbin/ip xfrm policy add src $LOCAL dst $REMOTE proto udp sport $LPORT dport $RPORT dir in tmpl src $LOCAL dst $REMOTE proto esp reqid $RREQ mode transport

/sbin/ip l2tp add tunnel local $REMOTE remote $LOCAL tunnel_id 2 peer_tunnel_id 1 encap udp udp_sport $RPORT udp_dport $LPORT
/sbin/ip l2tp add session name l2tp0 session_id 2 peer_session_id 1 tunnel_id 2
/sbin/ip link set dev l2tp0 up
/sbin/ip addr add 10.128.128.2/29 dev l2tp0
