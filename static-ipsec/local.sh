#!/bin/bash

. vars 

/sbin/modprobe l2tp_eth


/sbin/ip xfrm state add src $LOCAL dst $REMOTE proto esp spi $LSPI reqid $LREQ mode transport auth sha256 $LKEYAUTH enc aes $LKEYENC sel src $LOCAL dst $REMOTE

/sbin/ip xfrm state add src $REMOTE dst $LOCAL proto esp spi $RSPI reqid $LREQ mode transport auth sha256 $RKEYAUTH enc aes $RKEYENC sel src $REMOTE dst $LOCAL

/sbin/ip xfrm policy add src $LOCAL dst $REMOTE proto udp sport $LPORT dport $RPORT dir out tmpl src $LOCAL dst $REMOTE proto esp reqid $LREQ mode transport
/sbin/ip xfrm policy add src $REMOTE dst $LOCAL proto udp sport $RPORT dport $LPORT dir in tmpl src $REMOTE dst $LOCAL proto esp reqid $LREQ mode transport

/sbin/ip l2tp add tunnel local $LOCAL remote $REMOTE tunnel_id 1 peer_tunnel_id 2 encap udp udp_sport $LPORT udp_dport $RPORT
/sbin/ip l2tp add session name l2tp0 session_id 1 peer_session_id 2 tunnel_id 1
/sbin/ip link set dev l2tp0 up
