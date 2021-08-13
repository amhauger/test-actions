#!/bin/bash

set -euo pipefail

# MAJOR_VERSION=3
# MINOR_VERSION=-1
# PATCH_VERSION=-1
# LATEST_TAG=-1
V_TYPE="qa-"
VERSION="qa-v0.0.0"

usage() { echo "Usage: $0 [-n <qa|prod> environment] [-m <string> commit message]" 1>&2; exit 1;}

getVersions() {
    # Set default MAJOR, MINOR, and PATCH versions
    MAJOR_VERSION=3
    MINOR_VERSION=-1
    PATCH_VERSION=-1

    if [ -n "$1" ]; then
        IFS='.'
        read -a strarr <<< "${1}"
        MAJOR_VERSION=3
        MINOR_VERSION=${strarr[1]}
        PATCH_VERSION=${strarr[2]}

        if [ -z "$MAJOR_VERSION" ]; then
            MAJOR_VERSION=3
        fi
        if [ -z "$MINOR_VERSION" ]; then
            MINOR_VERSION=0
        fi
        if [ -z "$PATCH_VERSION" ]; then
            PATCH_VERSION=0
        fi
    fi
}

setVersion() {
    IFS=':'
    read -a strarr <<< "$1"
    if [ ${strarr[0]} == "fix" ] || [ ${strarr[0]} == "chore" ]; then
        ((PATCH_VERSION++))
    else
        ((MINOR_VERSION++))
    fi

    if [ $MINOR_VERSION == -1 ]; then 
        MINOR_VERSION=0
    fi

    if [ $PATCH_VERSION == -1 ]; then
        PATCH_VERSION=0
    fi

    VERSION=v$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION
}

while getopts "m:" flag
do
    case $flag in
        m)
            m=${OPTARG}
            LATEST_TAG=$(git tag -l "v*" | tail -1 | sed 's/v//')

            getVersions $LATEST_TAG
            setVersion $m
            echo "::set-output name=new_tag::$VERSION"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${m}" ]; then
    usage
fi