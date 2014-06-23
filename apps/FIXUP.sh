#!/bin/bash

#
# Run this script to remake the Android.mk in this directory after
# adding/removing .apk files.
#

echo 'LOCAL_PATH := $(my-dir)'
echo ''

for i in *.apk
do
  base=$(echo $i | sed 's/\.apk$//')
  echo "###############################################################################"
  echo "include \$(CLEAR_VARS)"
  echo ""
  echo "LOCAL_MODULE := $base"
  echo "LOCAL_MODULE_TAGS := optional"
  echo "LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk"
  echo "LOCAL_MODULE_CLASS := APPS"
  echo "LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)"
  echo "LOCAL_CERTIFICATE := PRESIGNED"
  echo ""
  echo "include \$(BUILD_PREBUILT)"
done
