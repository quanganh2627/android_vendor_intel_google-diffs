#!/bin/bash

# run this script with parameter android-main codebase dir.
# .i.e: ./adjust_patch_name.sh /home/jinwei/data/android/jb-main-latest

#set -x

ANDROID_MAIN=$1
ROOT_DIR=
PATCH_DIR=

declare -i tag=0

function get_root_dir()
{
	if [ "${ANDROID_BUILD_TOP}" != "" ]
	then
		ROOT_DIR=${ANDROID_BUILD_TOP}
	else
		ret=`cat Makefile 2>/dev/null | grep "include build/core/main.mk"`
		if [ "$ret" != "" ]
		then
			ROOT_DIR=`pwd`
		else
			echo "Do the source & lunch first or launch this from android build top directory"
			exit
		fi
	fi
}

function get_patch_dir()
{
	DIFFS_DIR=${ROOT_DIR}/vendor/intel/google_diffs

	i=0
	for dir in `find ${DIFFS_DIR} -name patches 2> /dev/null`
	do
		BRANCH[${i}]=`echo ${dir} | awk -F '/' '{ print $(NF-1) }'`
		echo "${i}.${BRANCH[${i}]}"
		i=`expr $i + 1`
	done
	echo "Pick the branch:"
	read option
	if [ "${BRANCH[$option]}" != "" ]
	then
		PATCH_DIR=${DIFFS_DIR}/${BRANCH[$option]}/patches
	else
		echo "Not supported!"
		exit
	fi
}

function do_rename()
{
	tag=0
	file=$1

	filename=`basename $file`
	dir=`dirname $file`
	changeid=`grep Change-Id $file`

	for f in `find $ANDROID_MAIN/$dir/PATCHES/ -name *.patch 2> /dev/null`
	do
		grep "$changeid" $f > /dev/null
		if [ $? -eq 0 ]; then
			tag=1
			tmpfilename=`basename $f`
			id=`echo "$tmpfilename" | awk -F- '{print $1}'`
			#newname=`echo "$filename" | sed "s/^[0-9]*/${id}00/"`
			newname=`echo "$tmpfilename" | sed "s/^[0-9]*/${id}00/"`
			if [ "$filename" != "$newname" ]; then
				mv $file $dir/$newname
				echo "$dir: $filename ---> $newname"
			fi
			break
		fi
	done

	#patch does not exist under main branch, which means it was added by building pdk
	#add '9' to the name for indetify.
	if [ $tag == 0 ]; then
		newname=`echo "$filename" | sed -e "s/^\([0-9]*\)/9\1@@/" -e "s/@@/00/"`
		mv $file $dir/$newname
		echo "$dir: $filename ---> $newname"
	fi
}

function adjust_patch_name()
{
	cd $PATCH_DIR
	if [ $? -ne  0 ]; then
		echo "no such patch directory: $PATCH_DIR"
		exit
	fi

	for file in `find . -name *.patch`
	do
		do_rename $file
	done

}

function main()
{
	if [ $# -ne 1 ]; then
		echo "please provide main branch codebase dir and ensure patch set was generated in advance."
		exit
	fi

	get_root_dir
	get_patch_dir
	adjust_patch_name
}

main
