#!/bin/bash

if [ "${ANDROID_BUILD_TOP}" != "" ]
then
    ret=`pwd | grep "${ANDROID_BUILD_TOP}"`
    if [ "$ret" != "" ]
    then
        ROOT_DIR=${ANDROID_BUILD_TOP}
    fi
fi
if [ "$ROOT_DIR" = "" ]
then
    ret=`cat Makefile 2>/dev/null | grep "include build/core/main.mk"`
    if [ "$ret" != "" ]
    then
        ROOT_DIR=`pwd`
    else
        echo "Do the source & lunch first or launch this from android build top directory"
        exit
    fi
fi

DIFFS_DIR=${ROOT_DIR}/vendor/intel/google_diffs

# Enable the temporary Makefile to abort the build in case of failure
(\cp ${DIFFS_DIR}/Show-stopper.mk ${DIFFS_DIR}/Android.mk)

if [ $# -eq 1 ]
then
    PATCH_DIR=${DIFFS_DIR}/${1}/patches
elif [ $# -eq 0 ]
then
    i=0
    for dir in `find ${DIFFS_DIR} -name patches`
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
else
    echo "option format illegal!"
    echo "exit"
fi

cd ${PATCH_DIR}
if [ $? -ne  0 ]
then
    echo "no such patch directory: ${PATCH_DIR}"
    exit
fi

for proj in `find . -type d -name "*"`
do
    ls ${proj}/*.patch 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]
    then
        continue
    fi
    echo "Applying patches under ${proj}..."
    for patch_name in `ls ${PATCH_DIR}/${proj}`
    do
        if [ -e ${ROOT_DIR}/${proj} ]; then
            cd ${ROOT_DIR}/${proj}
        else
            echo "no source code, skip dir: ${ROOT_DIR}/${proj}"
            break
        fi

        patch=${PATCH_DIR}/${proj}/${patch_name}
        change_id=`grep -w "^Change-Id:" ${patch} | awk '{print $2}'`
        ret=`git log | grep -w "^    Change-Id: ${change_id}" 2>/dev/null`
        if [ "${ret}" == "" ]
        then
            echo "Applying ${patch_name}"
            git am -k -3 --ignore-space-change --ignore-whitespace ${patch}
            if [ $? -ne 0 ]
            then
                echo "Failed at ${proj}"
                echo "Abort..."
                exit
            fi
        else
            echo "Applying ${patch_name}"
            echo "Applied, ignore and continue..."
        fi
    done
    cd ${PATCH_DIR}
done

# All went well, disable the show-stopper Makefile
(\rm -f ${DIFFS_DIR}/Android.mk)

