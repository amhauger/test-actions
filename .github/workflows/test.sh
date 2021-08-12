#!/bin/bash

while getopts ":n" opt; do
    case $opt in
        "qa") 
            echo "the environment is qa" >&2
            ;;
        "prod") 
            echo "the environment is prod" >&2
            ;;
        \?) 
            echo "invalid option $OPTARG" >&2
            exit 1
            ;;
        :)
            echo "$OPTARG requires an argument" >&2
            exit 1
            ;;
    esac
done