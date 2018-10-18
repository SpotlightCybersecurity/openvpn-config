#!/bin/bash
# Copyright 2018. Spotlight Cybersecurity LLC
# Released under an MIT license. See LICENSE file.

OPENVPN="`which openvpn`"
OPENSSL="`which openssl`"
EASYRSA="`which easyrsa 2> /dev/null`"
DIR="`dirname "${BASH_SOURCE[0]}"`"

function failexit() {
	echo "$1"
	exit 1
}

if [[ -z "${DIR}" ]]; then DIR="."; fi
if [[ -z "${OPENVPN}" ]]; then
	failexit "* openvpn binary not found!"
fi
if [[ -z "${OPENSSL}" ]]; then
	failexit "* openssl binary not found!"
fi
if [[ -z "$1" ]]; then
	failexit "* usage: $0 <PKIDIR> <SERVERNAME>"
fi
PKIDIR="$1"
if [[ -z "$2" ]]; then
	failexit "* usage: $0 <PKIDIR> <SERVERNAME>"
fi
SERVERCN="$2"

echo openvpn=$OPENVPN
echo openssl=$OPENSSL
echo dir=$DIR
if [[ -z "${EASYRSA}" ]]; then
	EASYRSA="$DIR/easyrsa/easyrsa"
fi
if [[ ! -f "${EASYRSA}" ]]; then
	EASYRSA="/usr/share/easy-rsa/3/easyrsa"
fi
if [[ ! -f "${EASYRSA}" ]]; then
	failexit "* easyrsa script not found!"
fi

if [[ -d "$PKIDIR" ]]; then
	echo "directory $PKIDIR already exists! using it"
else
	mkdir "$PKIDIR" || failexit "failed to create $PKIDIR"
fi
PKIBASENAME="`basename "$PKIDIR"`"

echo "$SERVERCN" > "$PKIDIR/servercn"

if [[ ! -d "$PKIDIR/ca" ]]; then
	"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch init-pki || failexit "* error initializing pki"
fi
# TODO: we're not getting the CN set correctly here for the CA. I think I
# fixed it, but we need to check
if [[ ! -f "$PKIDIR/ca/ca.crt" ]]; then
	"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch --req-cn="$PKIBASENAME" build-ca || failexit "* error creating CA root"
fi
if [[ ! -f "$PKIDIR/ca/private/$SERVERCN.key" ]]; then
	"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch --req-cn="$SERVERCN" gen-req "$SERVERCN" nopass || failexit "* error creating server request"
fi
if [[ ! -f "$PKIDIR/ca/issued/$SERVERCN.crt" ]]; then
"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch sign-req server "$SERVERCN" || failexit "* error signing server request"
fi

if [[ ! -f "$PKIDIR/dh.pem" ]]; then
	$OPENSSL dhparam -out "$PKIDIR/dh.pem" 2048 || failexit "* error generating dh params"
fi

if [[ ! -f "$PKIDIR/ta.key" ]]; then
	$OPENVPN --genkey --secret "$PKIDIR/ta.key" || failexit "* error generating openvpn tls-auth key"
fi

if [[ ! -d "$PKIDIR/ovpn" ]]; then
	mkdir "$PKIDIR/ovpn" || failexit "* failed to create $PKIDIR/ovpn"
fi

OUTPUT="$PKIDIR/ovpn/server.ovpn"
cat "$DIR/base.ovpn" > "$OUTPUT"
cat "$DIR/server.ovpn" >> "$OUTPUT"
echo "<tls-auth>" >> "$OUTPUT"
cat "$PKIDIR/ta.key" >> "$OUTPUT"
echo "</tls-auth>" >> "$OUTPUT"
echo "<dh>" >> "$OUTPUT"
cat "$PKIDIR/dh.pem" >> "$OUTPUT"
echo "</dh>" >> "$OUTPUT"
echo "<ca>" >> "$OUTPUT"
cat "$PKIDIR/ca/ca.crt" >> "$OUTPUT"
echo "</ca>" >> "$OUTPUT"
echo "<key>" >> "$OUTPUT"
cat "$PKIDIR/ca/private/$SERVERCN.key" >> "$OUTPUT"
echo "</key>" >> "$OUTPUT"
echo "<cert>" >> "$OUTPUT"
cat "$PKIDIR/ca/issued/$SERVERCN.crt" >> "$OUTPUT"
echo "</cert>" >> "$OUTPUT"

echo "server ovpn is at $OUTPUT"
