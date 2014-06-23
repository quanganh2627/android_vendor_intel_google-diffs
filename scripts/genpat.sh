#!/bin/bash
#

# parse parameters
DEBUG=0
usage() {
	echo $0 "[-m1 snapshot manifest  -b2 working branch/tag/HEAD  -o output directory]"
}

dprint()
{
	echo $*
}

nprint()
{
	return;	
}


if [ $DEBUG -ne 0 ];then
	ECHO="dprint"
else
	ECHO="nprint"
fi
generate_patch()
{
	git_repo=$1
	manifest=$2
	branch=$3
	upstream=
	local printlog=0

        $ECHO "handling $git_repo(HEAD..$branch) ..."
	if [ ! -e $git_repo ];then
		echo "$git_repo: (deleted)"
		continue;
	fi

	if [ $git_repo == "vendor/intel/google_diffs" ];then
		echo "ignore the $git_repo"
		continue
	fi

	cd $top_dir/$git_repo

	#git rev-list ^$upstream $branch > /dev/null
	$ECHO pwd: `pwd`
	upstream=`grep -v "\!--" $top_dir/$manifest |grep "\"$git_repo\""|grep "revision"|sed 's/.*revision="//g'|sed 's/".*//g'`

	$ECHO "upstream: $upstream"
	if [ -z $upstream ];then
		mkdir -p $output/$git_repo
		echo "$git_repo: (created)"
		echo "	copied"
		cp -fr $top_dir/$git_repo/* $output/$git_repo
		cp -fr -L $top_dir/$git_repo/.git $output/$git_repo
		continue
	fi

	# get revision list
	git rev-parse $branch > /dev/null
	if [ $? -ne 0 ];then
		branch=${branch/*\//}
		git rev-parse $branch > /dev/null
	fi
	$ECHO "branch: $branch"
	revs=`git rev-list ^$upstream $branch --no-merges --reverse`
        if [ -z "$revs" ];then
		continue;
	fi
	count=10000;
	rm -fr 0001*.patch
	for rev in $revs;do
		$top_dir/vendor/intel/google_diffs/scripts/git format-patch -k $rev^..$rev > /dev/null

		oldpatch=`ls 0001*.patch`;
		if [ ! -z "$oldpatch" ];then
			if [ $printlog -eq 0 ];then
				echo "$git_repo: (modified)"
				# generate patches
				$ECHO "generating patchs for $git_repo..."
				mkdir -p $output/$git_repo
				printlog=1;
			fi
			count=`expr $count + 1`
			newpatch=`echo $oldpatch|sed s/0001/$count/g|sed s/^1//g`;
			mv $oldpatch $output/$git_repo/$newpatch
			echo "	$newpatch"
		fi
	done
}

if [ $# -lt 2 ];then usage;exit;fi

# redirect all err to a log
exec 2> /tmp/genpat.err

curr_branch=
last_manifest=
while getopts hm:b:o:f: opt
do
	case "${opt}" in
	h)
		usage
		exit 0;
		;;
	m)
		if [ "${OPTARG}" -eq "1" ];then
			last_manifest=$2
			echo last_manifest:$last_manifest
		fi
		OPTIND=0
		shift 2
		;;
	b)
		if [ "${OPTARG}" -eq "2" ];then
			curr_branch=$2
			echo curr_branch:$curr_branch
		fi
		OPTIND=0
		shift 2
		;;
	f)
		git_repos_list="${OPTARG}"
		;;
	o)
		output="${OPTARG}"
		;;
	?)
		echo "${OPTARG}"
		;;
	esac
done
shift $(($OPTIND-1))
upstream_rev_options=$*
$ECHO upstream_rev_options:$upstream_rev_options

if [ -z $last_manifest ];then
	last_manifest=".repo/manifest.xml"
	echo "manifest not existed. use default  $last_manifest"
fi

if [ ! -e $last_manifest ];then
	echo "$last_manifest not existed"
	exit 1
fi

if [ -z $curr_branch ];then
	echo "NO current branch. Set to HEAD"
	curr_branch="HEAD"
fi

$ECHO git_repos_list:$git_repos_list
if [ -n "$git_repos_list" ] && [ -e "$git_repos_list" ];then
	git_repos=`cat $git_repos_list`
	if [ -z "$git_repos" ];then
		echo "$git_repos_list is empty!exit"
		exit 0
	else
		echo "==============$git_repos_list================"
	fi
fi
$ECHO git_repos:$git_repos
# get repo list
if [ -z "$git_repos" ];then
	git_repos=`cat .repo/project.list`
fi
top_dir=`pwd`
$ECHO git_repos:$git_repos

echo "output folder is $output"
if [ -d "$output" ];then
	echo "delete old patch folder $output"
	rm -fr $output
fi

mkdir -p $output
cd $output
output=`pwd`
cd $top_dir

for git_repo in $git_repos;do
	cd $top_dir
        generate_patch $git_repo $last_manifest $curr_branch
done

