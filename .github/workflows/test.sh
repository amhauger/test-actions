#!/bin/bash

set -euo pipefail

MAJOR_VERSION=3
MINOR_VERSION=0
PATCH_VERSION=0
LATEST_TAG=-1
V_TYPE="qa-"
VERSION="qa-v0.0.0"

usage() { echo "Usage: $0 [-n <qa|prod> environment] [-m <string> commit message]" 1>&2; exit 1;}
getVersions() {
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
}

setVersion() {
    IFS=':'
    read -a strarr <<< $1
    if [ ${strarr[0]} == "fix" ] || [ ${strarr[0]} == "chore" ]; then
        PATCH_VERSION=${PATCH_VERSION+1}
    else
        MINOR_VERSION=${MINOR_VERSION+1}
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
                getVersions
            elif [ $n == "prod" ]; then
                LATEST_TAG=$(git tag -l "v*" | tail -1 | sed 's/v//')
                V_TYPE="v"
                getVersions
            else
                usage
            fi
            ;;
        m)
            m=${OPTARG}
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