#!/bin/bash

# This script is source by build/envsetup.sh

if [ -z "$KK_FUSION_PLATFORM_ZIP" ]; then
    
    # Set the platform.zip file.
    export KK_FUSION_PLATFORM_ZIP=$(pwd)/vendor/pdk/mini_x86/mini_x86-userdebug/platform/platform.zip
    
    # Patch the tree
    bash $(pwd)/vendor/intel/google_diffs/scripts/apply_patch.sh android_4.4
    
    # RE-Execute the contents of any vendorsetup.sh files we can find.
    for f in `test -d device && find device -maxdepth 6 -name 'vendorsetup.sh' 2> /dev/null` \
             `test -d vendor && find vendor -maxdepth 6 -name 'vendorsetup.sh' 2> /dev/null`
    do
        case "$f" in
            vendor/intel/google_diffs/vendorsetup.sh )
            continue
            ;;
        esac
     
        echo "including $f"
        . $f
    done
    unset f
fi
