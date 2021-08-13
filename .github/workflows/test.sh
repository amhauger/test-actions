#!/bin/bash

set -euo pipefail

MAJOR_VERSION=3
MINOR_VERSION=-1
PATCH_VERSION=-1
LATEST_TAG=-1
V_TYPE="qa-"
VERSION="qa-v0.0.0"

usage() { echo "Usage: $0 [-n <qa|prod> environment] [-m <string> commit message]" 1>&2; exit 1;}
getVersions() {
    if [ -z "$LATEST_TAG"]; then
        echo "{ message: no previous version set; latest-tag: ${LATEST_TAG} }"
        return 1
    fi

    IFS='.'
    read -a strarr <<< "$LATEST_TAG"
    MAJOR_VERSION=${strarr[0]}
    MINOR_VERSION=${strarr[1]}
    PATCH_VERSION=${strarr[2]}

    if [ -z "$MAJOR_VERSION" ]; then
        MAJOR_VERSION=0
    fi
    if [ -z "$MINOR_VERSION" ]; then
        MINOR_VERSION=0
    fi
    if [ -z "$PATCH_VERSION" ]; then
        PATCH_VERSION=0
    fi

    echo "{ message: got and parsed latest version; version-prefix: ${V_TYPE}; latest-version: ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION} }"
}

setVersion() {
    IFS=':'
    read -a strarr <<< "$1"
    if [ ${strarr[0]} == "fix" ] || [ ${strarr[0]} == "chore" ]; then
        echo "{ message: updating patch version; commit-type: ${strarr[0]}; previous-patch-version: ${PATCH_VERSION} }"
        ((PATCH_VERSION++))
        echo "{ message: updated patch version; commit-type: ${strarr[0]}; new-patch-version: ${PATCH_VERSION} }"
    else
        echo "{ message: updating minor version; commit-type: ${strarr[0]}; previous-minor-version: ${MINOR_VERSION} }"
        ((MINOR_VERSION++))
        echo "{ message: updated minor version; commit-type: ${strarr[0]}; previous-minor-version: ${MINOR_VERSION} }"
    fi

    if [ $MINOR_VERSION == -1 ]; then 
        MINOR_VERSION=0
    fi

    if [ $PATCH_VERSION == -1 ]; then
        PATCH_VERSION=0
    fi

    VERSION=$V_TYPE$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION
}

while getopts ":n:m:" flag
do
    case $flag in
        n)
            n=${OPTARG}
            if [ $n == "qa" ]; then
                LATEST_TAG=$(git tag -l "qa-v*" | tail -1 | sed 's/qa-v//')
                V_TYPE="qa-v"
                echo "{ message: tagging for qa; latest-tag: ${LATEST_TAG}; version-prefix: ${V_TYPE} }"
                getVersions
            elif [ $n == "prod" ]; then
                LATEST_TAG=$(git tag -l "v*" | tail -1 | sed 's/v//')
                V_TYPE="v"
                echo "{ message: tagging for prod; latest-tag: ${LATEST_TAG}; version-prefix: ${V_TYPE} }"
                getVersions
            else
                usage
            fi
            ;;
        m)
            m=${OPTARG}
            echo "{ message: setting version; commit-message: ${m}; latest-tag: ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION} }"
            setVersion $m
            git tag -a $VERSION -m "${m}"
            git push origin $VERSION
            echo "::set-output name=new_tag::$VERSION"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${n}" ] || [ -z "${m}" ]; then
    usage
fi

echo $VERSION