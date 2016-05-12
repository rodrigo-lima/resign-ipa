#!/usr/bin/env ruby
require "rubygems"
require "thor"
require "zip/zip"

class MyCLI < Thor
  class_option :verbose, :type => :boolean, :aliases => "-v"

  desc "resign", "Re-sign IPA"
  long_desc <<-LONGDESC
    `ipa-tools.rb resign` will re-sign the given IPA file using the provided distribution certificate.

    In order for it to work, you need to provide the IPA to be signed and the name of the distribution certificate to be used, for example: "iPhone Distribution: My Name"

    You also need to provide the 'mobileprovision' profile to be used.
    By default, the script searches the current folder for a file called 'mobileprovision.plist'.
    Optionally, you could provided the fully qualified path (-p argument).

    The script will also apply new Entitlements during signing, if it finds the file 'entitlements.plist' on the current directory.

    The default output is called 'signed.ipa' unless specified via -o argument.

    > $ ipa-tools.rb resign -i "My App.ipa" -e "My App" -c "iPhone Distribution: John Smith (1234)" -v

    > $ ipa-tools.rb resign -i "Another App.ipa" -e "Another App"  -c "iPhone Distribution: John Smith (1234)" -p "~/Downloads/Team_Provisioning.mobileprovision" -o "My-SignedApp.ipa"

LONGDESC
  option :ipa, :required => true, :type => :string, :aliases => "-i"
  option :executable, :required => true, :type => :string, :aliases => "-e"
  option :certificate, :required => true, :type => :string, :aliases => "-c"
  option :provisioning, :type => :string, :aliases => "-p"
  option :output, :type => :string, :aliases => "-o"
  def resign()
    ipa_file = options[:ipa]
    executable_name = options[:executable]
    say "\nRe-Sign #{ipa_file} / #{executable_name} ----------------",:cyan
    exit if not ipa_exists?(ipa_file)

    # UNZIP -------------------------------------------------------------------
    exit if not unzip_app(ipa_file, executable_name)

    # APP FOLDER --------------------------------------------------------------
    app_folder = find_app_folder 'Payload', 'app'

    # DISPLAY original bundleID -----------------------------------------------
    bundle_id = display_bundleid

    # fine mobileprovision ----------------------------------------------------
    mobile_provision = options[:provisioning]
    if not ipa_exists? mobile_provision
      mobile_provision = find_app_folder '.', 'mobileprovision.plist'
      if not mobile_provision
        skip_mobile_provision = false
        while not skip_mobile_provision
          mobile_provision = ask <<BIG_QUESTION

'mobileprovision.plist' not found on working directory.
You *must* provide a mobileprovision file in order to be able to resign the IPA.
Please enter the location of the mobileprovision file, or 'Enter' to cancel:
BIG_QUESTION

          if mobile_provision.length == 0 # user just hit enter
            skip_mobile_provision = true
          else
            if not File.exists? mobile_provision # otherwise, let's validate it
              mobile_provision = nil
            end
          end
        end
      end
    end
    if mobile_provision.length == 0
      say "\nCould not find mobile_provision, existing...", :red
      exit
    end
    say "\nUsing mobile_provision file: '#{mobile_provision}'", :cyan

    # find entitlements  ------------------------------------------------------
    entitlements = find_app_folder '.', 'entitlements.plist'
    if not entitlements
      skip_entitlements = false
      while not skip_entitlements
        entitlements = ask <<BIG_QUESTION

'entitlements.plist' not found on working directory.
If you want to replace entitlements, please enter the full path, otherwise just hit 'Enter':
BIG_QUESTION

        if entitlements.length == 0 # user just hit enter
          skip_entitlements = true
        else
          if not File.exists? entitlements # otherwise, let's validate it
            entitlements = nil
            skip_entitlements = yes?"Could not find entitlements.plist in #{entitlements}. Do you want to skip replacing the entitlements on the re-signed IPA? Y/(N): ",:green
          end
        end
      end
    end
    say "\nWill *not* replace entitlements", :cyan if entitlements.length == 0
    say "\nReplace entitlements with contents of '#{entitlements}'", :cyan if entitlements.length > 0

    # DISPLAY original mobileprovision ----------------------------------------
    replace_bundle_id = yes? "\nDo you want to replace BundleID: #{bundle_id} ? Y/(N): ",:green
    if replace_bundle_id
      new_bundle_id = ask "\nEnter new BundleID: "
      if new_bundle_id.length > 0
        plist_buddy("Payload/#{app_folder}/Info.plist",'Set','CFBundleIdentifier', new_bundle_id)
        say "\nNew bundleID set to #{new_bundle_id}", :cyan
        bundle_id = new_bundle_id
      end
    end


    # working ----------------------------------------
    say "\nWorking....", :cyan
    say "\nDelete existing _CodeSignature and CodeResources...",:yellow if options[:verbose]
    FileUtils.rm_rf "Payload/#{app_folder}/_CodeSignature"
    FileUtils.rm_rf "Payload/#{app_folder}/CodeResources"

    say "\nCopy new Provisioning Profile",:yellow if options[:verbose]
    FileUtils.cp mobile_provision, "Payload/#{app_folder}/embedded.mobileprovision"

    say "\nTrying to re-sign now....",:yellow if options[:verbose]
    say "\nExecuting this command: /usr/bin/codesign -f -s '#{options[:certificate]}' -i '#{bundle_id}' --entitlements '#{entitlements}' -vv 'Payload/#{app_folder}'", :yellow if options[:verbose]
    `/usr/bin/codesign -f --verbose -s "#{options[:certificate]}" -i "#{bundle_id}" --entitlements "#{entitlements}" -vv "Payload/#{app_folder}"`

    say "\nNow zipping it up...",:yellow if options[:verbose]
    signed_ipa = options[:output]
    if !signed_ipa || signed_ipa.length == 0
      signed_ipa = "signed.ipa"
    end
    # clean up
    FileUtils.rm_rf(signed_ipa)
    say "\nCreating... #{signed_ipa} file.",:cyan
    `zip --symlinks --recurse-path -9 "#{signed_ipa}" Payload`

    say "\nDONE! ----------------\n\n", :cyan

  end

  # UNZIP -------------------------------------------------------------------
  desc "unzip_app", "Unzip APP file"
  def unzip_app(ipa_file, executable_name)
    if not ipa_exists?(ipa_file)
      false
    end

    # do unzip
    should_remove = true
    if File.exist?('Payload')
      should_remove = yes?"\nPayload folder already exists, do you want to override? Y/(N): ",:green
      # puts "response = #{should_remove}"
    end

    if should_remove
      say "\nUnzipping IPA - #{ipa_file}", :cyan
      unzip_file(ipa_file, ".", should_remove)
    end

    say "\n... Making sure App is executable ...", :cyan
    app_folder = find_app_folder 'Payload', 'app'
    if app_folder
      ext = File.extname(app_folder)
      file_no_ext = "Payload/#{app_folder}/#{executable_name}"
      say "... THIS is the file #{file_no_ext} ...", :cyan
      FileUtils.chmod "a+x", file_no_ext if File.exists?(file_no_ext)
    end

    true
  end


  # DISPLAY original bundleID --------------------------------------------------
  desc "display_bundleid", "print APP's bundleID"
  def display_bundleid()
    app_folder = find_app_folder 'Payload', 'app'
    bundle_id = ''
    if app_folder
      bundle_id = plist_buddy("Payload/#{app_folder}/Info.plist",'Print','CFBundleIdentifier','')
      say "\nORIGINAL bundleID: '#{bundle_id}'", :cyan
    else
      say "\nCould not determine APP folder...."
    end
    bundle_id
  end

  # DISPLAY original mobileprovision ------------------------------------------
  desc "display_mobileprovision", "print APP's mobileprovision"
  def display_mobileprovision()
    app_folder = find_app_folder 'Payload', 'app'
    if File.exists?("Payload/#{app_folder}/embedded.mobileprovision")
      `security cms -D -i "Payload/#{app_folder}/embedded.mobileprovision" > mobileprovision.plist`
    else
      say "\nNo embedded.mobileprovision...",:cyan
    end
  end


  # ===========================================================================
  # helper stuff
  # ===========================================================================
  no_commands {
    def plist_buddy(file,command,key,value='')
      output = `/usr/libexec/PlistBuddy -c "#{command} :#{key} #{value}" '#{file}' 2> /dev/null`
      !output || output.empty? || /Does Not Exist/ === output ? nil : output.strip
    end

    def find_app_folder(folder,extension)
      return nil if !File.exist? folder
      app_folder = nil
      Dir.new(folder).each  {|x|
         say "Examining #{folder}/#{x}",:yellow if options[:verbose]
         app_folder = x if x.end_with?(extension)
         break if app_folder
      }
      say "Found #{extension} in #{folder}: #{app_folder}",:yellow if app_folder && options[:verbose]
      app_folder
    end

    def ipa_exists?(ipa_file)
      if !ipa_file || ipa_file.length == 0
        false
      elsif !File.exists? ipa_file
        say "Can't find file - #{ipa_file}", :red
        false
      else
        true
      end
    end

    def unzip_file (file, destination, force)
      say "\nRemoving previous 'Payload' folder",:yellow if File.exist?('Payload') && force && options[:verbose]
      FileUtils.rm_rf('Payload') if force

      Zip::ZipFile.open(file) { |zip_file|
       say "unzipping... #{zip_file}",:yellow if options[:verbose]
       zip_file.each { |f|
         f_path = File.join(destination, f.name)
         # say "unzipping... #{f_path}",:yellow if options[:verbose]
         FileUtils.mkdir_p(File.dirname(f_path))
         zip_file.extract(f, f_path) unless File.exist?(f_path)
       }
      }
    end
  }

end


MyCLI.start(ARGV)
