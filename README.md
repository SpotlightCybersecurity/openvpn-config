These scripts are to automate generating the public key infrastructure (PKI), other needed keys, and OpenVPN configs needed to use OpenVPN. The [easy-rsa][1] makes it easy to manage PKI, but doesn't help you (directly) with making OpenVPN configs for OpenVPN clients and servers.

# Prerequisites
These scripts use [easy-rsa][1] to make the PKI stuff easier and safer. You'll need to install it.

In fedora, do a `dnf install easy-rsa`

Or go to <https://github.com/OpenVPN/easy-rsa/releases> to download the latest release. Create the `easyrsa` directory in this directory and unpack the contents there. Or put it on your path.

# Customize Base Configs
There are 3 template files: `base.ovpn` (used for both client and servers), `server.ovpn` (used just for the OpenVPN server), and `client.ovpn` (used just for the OpenVPN clients). If you want to customize these files, configure them now! The scripts will add the server's FQDN as well as the `tls-auth`, `dh`, `ca`, `key` (private key), and `cert` (public cert) tags for you.

These files *should* contain sensible secure defaults!

# Build the Certificate Authority and Server OVPN
First decide on a directory that will store your PKI Certificate Authority and keys. Some keys will be stored unencrypted to you'll want to keep this directory safe! It does not need to exist, the script will create it.
```
./ovpn-build-ca.sh /path/to/a/directory/for/the/ca name.of.vpnserver.com
```

The server's FQDN, the 2nd parameter to the script, will get saved in the PKI CA directory for use in later configs.

You'll be prompted to create a password for the Certificate Authority's private key. Remember it! You won't be able to recover it if lost...

At the end, the script will tell you where is stored the server's OVPN file.

# Build a Client key/certificate and OVPN
```
./ovpn-client.sh /path/to/a/directory/for/the/ca clientname
```

The `clientname` above just needs to be a name you can recognize the client by. It doesn't have to be a proper FQDN. 

You'll be prompted to enter the CA private key's password. I hope you remembered it from above! :)

At the end, the script will tell you where is stored the client's OVPN file.

Voila! Quick and easy OpenVPN configs!
