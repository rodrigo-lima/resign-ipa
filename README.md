ipa-tools
==========

**ipa-tools.rb** resign will re-sign the given IPA file using the provided distribution certificate.

In order for it to work, you must provide the following:

- **-i** -- IPA file name to be signed. Example: `-i "My_App.ipa"`
- **-e** -- Executable file name. Example: `-e "My App"`
- **-c** -- distribution certificate to be used. Example: `-c "iPhone Distribution: John Smith (1234)"`
- **-p** -- mobileprovision file. By default, it'll look for a file called **mobileprovision.plist**, or you could specify the full path with **-p**. Example: `-p "~/Downloads/Team_Provisioning.plist"`
- **-o** -- output signed IPA file name. Example: `-o "Signed_App.ipa`

The script will also apply new **Entitlements** during signing. It searches for a file *'entitlements.plist'* on the current directory, and will ask you for a full file path if it cannot find.

After signed, the default output is called **'signed.ipa'** unless specified via -o argument.

A sample shell script - run_resign.sh - has been provided with most common options pre-set. Just update the variables on the top and run this shell script.

```
> $ ipa-tools.rb resign -i "My App.ipa" -c "iPhone Distribution: John Smith (1234)" -v
>
> $ ipa-tools.rb resign -i "Another App.ipa" \
                        -c "iPhone Distribution: John Smith (1234)" \
                        -p "~/Downloads/Team_Provisioning.plist" \
                        -o "My-SignedApp.ipa" \
                        -v
```

Requirements
====
- RubyGems -- [download](https://rubygems.org/pages/download)
- thor -- [info](https://rubygems.org/gems/thor)
- zip -- [info](https://rubygems.org/gems/zip)

References
====
- [Checking Distribution Entitlements](https://developer.apple.com/library/ios/qa/qa1798/_index.html)

