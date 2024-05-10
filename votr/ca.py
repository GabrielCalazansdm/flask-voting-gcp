import os
import sys
import random
from OpenSSL import crypto

###########
# CA Cert #
###########

ca_key = crypto.PKey()
ca_key.generate_key(crypto.TYPE_RSA, 2048)

ca_cert = crypto.X509()
ca_cert.set_version(2)
ca_cert.set_serial_number(random.randint(50000000,100000000))

ca_subj = ca_cert.get_subject()
ca_subj.commonName = "My CA"

ca_cert.add_extensions([
    crypto.X509Extension("subjectKeyIdentifier", False, "hash", subject=ca_cert),
])

ca_cert.add_extensions([
    crypto.X509Extension("authorityKeyIdentifier", False, "keyid:always", issuer=ca_cert),
])

ca_cert.add_extensions([
    crypto.X509Extension("basicConstraints", False, "CA:TRUE"),
    crypto.X509Extension("keyUsage", False, "keyCertSign, cRLSign"),
])

ca_cert.set_issuer(ca_subj)
ca_cert.set_pubkey(ca_key)

ca_cert.gmtime_adj_notBefore(0)
ca_cert.gmtime_adj_notAfter(10*365*24*60*60)
ca_cert.sign(ca_key, 'sha256')

# Save certificate
with open("ca.crt", "wt") as f:
    f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, ca_cert))

# Save private key
with open("ca.key", "wt") as f:
    f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, ca_key))

###############
# Client Cert #
###############

client_key = crypto.PKey()
client_key.generate_key(crypto.TYPE_RSA, 2048)

client_cert = crypto.X509()
client_cert.set_version(2)
client_cert.set_serial_number(random.randint(50000000,100000000))

client_subj = client_cert.get_subject()
client_subj.commonName = "Client"

client_cert.add_extensions([
    crypto.X509Extension("basicConstraints", False, "CA:FALSE"),
    crypto.X509Extension("subjectKeyIdentifier", False, "hash", subject=client_cert),
])

client_cert.add_extensions([
    crypto.X509Extension("authorityKeyIdentifier", False, "keyid:always", issuer=ca_cert),
    crypto.X509Extension("extendedKeyUsage", False, "clientAuth"),
    crypto.X509Extension("keyUsage", False, "digitalSignature"),
])

client_cert.set_pubkey(client_key)
client_cert.sign(ca_key, 'sha256')

client_cert.gmtime_adj_notBefore(0)
client_cert.gmtime_adj_notAfter(10*365*24*60*60)
client_cert.set_issuer(ca_subj)

# Save certificate
with open("client.crt", "wt") as f:
    f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, client_cert))

# Save private key
with open("client.key", "wt") as f:
    f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, client_key))
