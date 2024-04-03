#!/bin/bash

script_dir="$(realpath $(dirname $0))"
openssl_path="$script_dir/macos-x86_64+arm64/openssl"
credentials_dir=$script_dir/../"Rutoken Tech/Credentials"

export OPENSSL_CONF="$script_dir/openssl.cnf"

declare -a sections=("ca" "bank" "rootCa")

# Generate keys
for sec in "${sections[@]}"
do
  rm "$credentials_dir/$sec.pem" "$credentials_dir/$sec.key" 2>/dev/null

$openssl_path \
  genpkey -engine rtengine -algorithm gost2012_256 -pkeyopt paramset:A -out "$credentials_dir/$sec.key"
done

# Generate certificate for the CA
$openssl_path \
  req -engine rtengine -utf8 -new -x509 -md_gost12_256 \
  -utf8 -config "$script_dir/ca.conf" -days 3650 -key "$credentials_dir/ca.key" -out "$credentials_dir/ca.pem"

# Generate certificate for the Root CA
$openssl_path \
  req -engine rtengine -utf8 -new -x509 -md_gost12_256 \
  -utf8 -config "$script_dir/rootCa.conf" -days 3650 -key "$credentials_dir/rootCa.key" -out "$credentials_dir/rootCa.pem"

# Generate CSR for the Bank
$openssl_path \
  req -engine rtengine -utf8 -new -md_gost12_256 \
  -utf8 -config "$script_dir/bank.conf" -key "$credentials_dir/bank.key" -out "$credentials_dir/bank.csr"

# Sign CSR of the Bank with Root CA
$openssl_path \
  x509 -engine rtengine -req -md_gost12_256 -CA "$credentials_dir/rootCa.pem" -CAkey "$credentials_dir/rootCa.key" \
  -in "$credentials_dir/bank.csr" -out "$credentials_dir/bank.pem" -days 3650 -CAcreateserial