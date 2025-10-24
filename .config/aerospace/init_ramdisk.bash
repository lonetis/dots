#!/usr/bin/env bash

if [ ! -d "/Volumes/ramdisk" ]; then
    # ram://XXXX = YYYY * 2048 where YYYY is the size in MB
    diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nobrowse -nomount ram://2048`
    echo "Ramdisk created"
else
    echo "Ramdisk already exists"
fi
