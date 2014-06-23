#!/bin/bash
#

# parse parameters
top_dir=`pwd`

temp_patches="patches"

if [ $# -eq 1 ]
then
    new_patches=${1}
elif [ $# -eq 0 ]
then
    new_patches=android_4.4
else
    echo "option format illegal!"
    echo "exit"
    exit
fi

cd $top_dir/vendor/intel/google_diffs/$new_patches/patches/
if [ $? -ne  0 ]
then
   mkdir -p $top_dir/vendor/intel/google_diffs/$new_patches/patches/
fi

cd $top_dir

./vendor/intel/google_diffs/scripts/genpat.sh -o $temp_patches
python vendor/intel/google_diffs/scripts/gen_commit.py $temp_patches $new_patches
cd $top_dir/vendor/intel/google_diffs
#./scripts/add_bz.sh ./$new_patches/patches
git add $new_patches/patches/
cd $top_dir
rm -fr $temp_patches
