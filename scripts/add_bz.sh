#!/bin/bash
#set -x

#bugzilla number for different tags of pdk patches
PDK_MR2_TEMP=117199
PDK_MR2_ABSP=117349
PDK_MR2_AOSP=117351
MERGE_TO_MAIN=117356

find_no_bz()
{
	for f in `find $1 -name "*.patch" 2> /dev/null`
	do
		grep "BZ:" $f > /dev/null
		if [ $? -ne 0 ]; then
			echo $f >> no_bz_list
		fi
	done
}

add_bz()
{
	tag=$1
	bugID=$2
	for f in `grep -i $tag no_bz_list`
	do
		sed -i '4a\
\
BZ: '$bugID $f
	done
}

main()
{
	find_no_bz $1

	add_bz "PDK-MR2-TEMP" $PDK_MR2_TEMP
	add_bz "PDK-MR2-ABSP" $PDK_MR2_ABSP
	add_bz "PDK-MR2-AOSP" $PDK_MR2_AOSP
	add_bz "MERGE-TO-MAIN" $MERGE_TO_MAIN

	rm -f no_bz_list
}

main $1
