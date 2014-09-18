resign-ipa
==========

**ipa-tools.rb** resign will re-sign the given IPA file using the provided distribution certificate.

In order for it to work, you need to provide the IPA to be signed and the name of the distribution certificate to be used, for example: *"iPhone Distribution: My Name"*

You also need to provide the mobileprovision profile to be used.
By default, the script searches the current folder for a file called *'mobileprovision.plist'*.
Optionally, you could provided the fully qualified path (-p argument).

The script will also apply new Entitlements during signing, if it finds *'entitlements.plist'* file on the current directory.

After signed, the default output is called **'signed.ipa'** unless specified via -o argument.

```
> $ ipa-tools.rb resign -i "My App.ipa" -c "iPhone Distribution: John Smith (1234)" -v
>
> $ ipa-tools.rb resign -i "Another App.ipa" \
                        -c "iPhone Distribution: John Smith (1234)" \
                        -p "~/Downloads/Team_Provisioning.plist" \
                        -o "My-SignedApp.ipa" \
                        -v
```
