#!/usr/bin/env bash

# -- update these
IPA_NAME="YOUR_APP.ipa"
EXE_NAME="YOU APP"
MOBILE_PROVISION="YOUR_PROVISION.mobileprovision"
CERT_NAME="iPhone Distribution: John Smith (12345ABCDE)"

# - clean up
echo "REMOVE OLD PAYLOAD FOLDER...."
rm -rf Payload

echo "RUN RE-SIGN...."
./ipa-tools.rb resign -i $IPA_NAME  \
                      -e "$EXE_NAME"  \
                      -c "$CERT_NAME" \
                      -p $MOBILE_PROVISION \
                      -o "signed-$IPA_NAME" -v

