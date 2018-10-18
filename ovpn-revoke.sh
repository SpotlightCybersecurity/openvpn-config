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

"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch revoke "$CLIENTCN" || failexit "* error revoking client request"
"$EASYRSA" --pki-dir="$PKIDIR/ca" --batch gen-crl || failexit "* error generating CRL"
echo "CRL is stored at: $PKIDIR/ca/crl.pem"
