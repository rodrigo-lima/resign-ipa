#!/usr/bin/env bash 

# -- update these
IPA_NAME="YOUR_APP.ipa"
MOBILE_PROVISION="YOUR_PROVISION.mobileprovision"
CERT_NAME="iPhone Distribution: John Smith (12345ABCDE)"                                           
# --

./ipa-tools.rb resign -i $IPA_NAME  \
                      -c "$CERT_NAME" \
                      -p $MOBILE_PROVISION \
                      -o "signed-$IPA_NAME" -v

