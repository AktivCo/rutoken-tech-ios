#!/bin/bash

script_dir="$(realpath $(dirname $0))"
openssl_path="$script_dir/macos-x86_64+arm64/openssl"
credentials_dir=$script_dir/../"Rutoken Tech/Credentials"

export OPENSSL_CONF="$script_dir/openssl.cnf"

declare -a sections=("ca" "bank")

for sec in "${sections[@]}"
do
  rm "$credentials_dir/$sec.pem" "$credentials_dir/$sec.key" 2>/dev/null

$openssl_path \
  genpkey -engine rtengine -algorithm gost2012_256 -pkeyopt paramset:A -out "$credentials_dir/$sec.key"


$openssl_path \
  req -engine rtengine -utf8 -new -x509 -md_gost12_256 \
  -utf8 -config "$script_dir/cert.conf" -days 3650 -key "$credentials_dir/$sec.key" -out "$credentials_dir/$sec.pem"
done
