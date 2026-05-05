#!/bin/bash
set -e

testAlias+=(
	[fedenunez/openvpn]='openvpn'
)

imageTests+=(
	[openvpn]='
	paranoid
        conf_options
        client
        basic
        dual-proto
        otp
	iptables
	revocation
	'
)
