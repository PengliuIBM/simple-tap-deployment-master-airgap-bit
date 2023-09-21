#!/usr/bin/env bash

# OpenSSL requires the port number.
SERVER=$1
DELAY=1
ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo Obtaining cipher list from $(openssl version).

# Variables to store the weak ciphers
weak_ciphers=()
found_weak_cipher=false

for cipher in ${ciphers[@]}
do
  echo -n Testing $cipher...
  result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER 2>&1)
  if [[ "$result" =~ ":error:" ]] ; then
    error=$(echo -n $result | cut -d':' -f6)
    echo NO \($error\)
  else
    if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]] ; then
      key_size=$(echo "$result" | awk '/Cipher is/ {print $3}' | cut -d'-' -f2)
      if [[ $key_size -lt 256 ]]; then
        echo "NO (Weak key size: ${key_size})"
        weak_ciphers+=($cipher)
        found_weak_cipher=true
      else
        echo YES
      fi
    else
      echo UNKNOWN RESPONSE
      echo $result
    fi
  fi
  sleep $DELAY
done

# Print Pass/Fail result
if [[ $found_weak_cipher == true ]]; then
  echo "Fail"
  echo "Weak ciphers accepted:"
  printf '%s\n' "${weak_ciphers[@]}"
else
  echo "Pass"
fi
