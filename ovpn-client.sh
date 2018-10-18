#!/bin/bash
# Copyright 2018. Spotlight Cybersecurity LLC
# Released under an MIT license. See LICENSE file.

DIR="`dirname "${BASH_SOURCE[0]}"`"
EASYRSA="`which easyrsa 2> /dev/null`"

function failexit() {
	echo "$1"
	exit 1
}

if [[ -z "${DIR}" ]]; then DIR="."; fi
if [[ -z "$1" ]]; then
	failexit "* usage: $0 <PKIDIR> <CLIENTNAME>"
fi
PKIDIR="$1"
if [[ -z "$2" ]]; then
	failexit "* usage: $0 <PKIDIR> <CLIENTNAME>"
fi
CLIENTCN="$2"

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


if [[ ! -f "$PKIDIR/ca/private/$CLIENTCN.key" ]]; then
	"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch --req-cn="$CLIENTCN" gen-req "$CLIENTCN" nopass || failexit "* error creating client request"
fi
if [[ ! -f "$PKIDIR/ca/issued/$CLIENTCN.crt" ]]; then
"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch sign-req client "$CLIENTCN" || failexit "* error signing client request"
fi

if [[ ! -f "$PKIDIR/ta.key" ]]; then
	failexit "* openvpn tls-auth key is missing! Run ovpn-build-ca.sh"
fi

if [[ ! -d "$PKIDIR/ovpn" ]]; then
	mkdir "$PKIDIR/ovpn" || failexit "* failed to create $PKIDIR/ovpn"
fi

OUTPUT="$PKIDIR/ovpn/$CLIENTCN.ovpn"
cat "$DIR/base.ovpn" > "$OUTPUT"
cat "$DIR/client.ovpn" >> "$OUTPUT"
if [[ -f "$PKIDIR/servercn" ]]; then
	echo "remote `cat "$PKIDIR/servercn"`" >> $OUTPUT
fi
echo "<tls-auth>" >> "$OUTPUT"
cat "$PKIDIR/ta.key" >> "$OUTPUT"
echo "</tls-auth>" >> "$OUTPUT"
echo "<ca>" >> "$OUTPUT"
cat "$PKIDIR/ca/ca.crt" >> "$OUTPUT"
echo "</ca>" >> "$OUTPUT"
echo "<key>" >> "$OUTPUT"
cat "$PKIDIR/ca/private/$CLIENTCN.key" >> "$OUTPUT"
echo "</key>" >> "$OUTPUT"
echo "<cert>" >> "$OUTPUT"
cat "$PKIDIR/ca/issued/$CLIENTCN.crt" >> "$OUTPUT"
echo "</cert>" >> "$OUTPUT"

echo "ovpn is at $OUTPUT"
