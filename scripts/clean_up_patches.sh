#!/bin/bash

GOOGLE_DIFFS=vendor/intel/google_diffs

PATCHED_PROJECTS=$(
  for i in ${GOOGLE_DIFFS}/*/patches
  do
    (
      cd $i
      find . -type d -print
    )
  done | sort -u |
    while read _dir
    do
      if [ -d $_dir/.git ]; then
        echo $_dir
      fi
    done
)

repo forall $PATCHED_PROJECTS -c git reset --hard m/integ/prek
repo forall $PATCHED_PROJECTS -c git clean -d -f -x
repo forall $PATCHED_PROJECTS -c git rebase --abort
repo forall $PATCHED_PROJECTS -c git am --abort

echo
echo Repo status for $PATCHED_PROJECTS
repo status $PATCHED_PROJECTS
