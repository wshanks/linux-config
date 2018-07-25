#!/usr/bin/env bash

ROOT_UID=0
set -e

if [ $UID != $ROOT_UID ]; then
    echo "This command requires root privileges to run."
    exit 1
fi

do_mount() {
    RAWFILE=$1
    LUKSNAME=$2
    MOUNTPOINT=$3

    LOOP="$(losetup -f $RAWFILE --show)" 
    set +e
    if [ "$(tty)" == "not a tty" ]; then
        PASSWD="$(zenity --entry --hide-text --title="LUKS passphrase")"
        echo $PASSWD | cryptsetup luksOpen $LOOP $LUKSNAME -
    else
        cryptsetup luksOpen $LOOP $LUKSNAME
    fi
    if (($? == 0)); then
        mount /dev/mapper/$LUKSNAME $MOUNTPOINT || cryptsetup luksClose $LUKSNAME
    fi
    ERR=$(cryptsetup status $LUKSNAME | head -n 1 | grep "/dev/mapper/$LUKSNAME is inactive.")
    set -e
    if [ -n "$ERR" ]; then
        losetup -d $LOOP
    fi
}

do_unmount() {
    MOUNTPOINT=$1
    RAWFILE=$2

    LUKSNAME="$(df $MOUNTPOINT | grep $MOUNTPOINT | awk '{ print $1 }' | sed 's/\/dev\/mapper\///')"
    LOOP="$(cryptsetup status $LUKSNAME | grep device: | awk '{ print $2 }')"

    umount $MOUNTPOINT
    cryptsetup luksClose $LUKSNAME
    losetup -d $LOOP
}

usage() {
    echo "Usage: luks_mount.sh -f RAWFILE -m MOUNTPOINT [-l LUKSNAME] [-u]"
}

main() {
    OPTIND=1
    MODE="mount"
    RAWFILE=""
    MOUNTPOINT=""
    LUKSNAME=""

    while getopts "f:m:l:u" opt; do
        case "$opt" in
            v)  verbose=1
                ;;
            u)  MODE="unmount"
                ;;
            f)  RAWFILE=$OPTARG
                ;;
            m)  MOUNTPOINT=$OPTARG
                ;;
            l)  LUKSNAME=$OPTARG
                ;;
        esac
    done

    shift $((OPTIND-1))

    if [ $MODE = "mount" ] ; then
        if [ -z "${RAWFILE}" ] || [ -z "${MOUNTPOINT}" ] || [ -z "${LUKSNAME}" ]; then
            echo "Must specify -f, -m, and -l flags to mount."
            usage
            exit 1
        fi
    else
         if [ -z "${MOUNTPOINT}" ] ; then
             echo "Must specify mount point to unmount."
             usage
             exit 1
         fi
    fi

    if [ $MODE = "mount" ] ; then
        do_mount $RAWFILE $LUKSNAME $MOUNTPOINT
    else
        do_unmount $MOUNTPOINT $RAWFILE
    fi
}


main "$@"
