#!/bin/bash
#https://www.jianshu.com/p/d72462b6c67c
if [[ -z "$1" ]]; then
    echo "Usage: $0 \"backupfile\""
else
    devstr="put ""$1""\nbye"
    devstr=`echo -e $devstr`
    cadaver https://dav.jianguoyun.com/dav/Minecraft/ <<< "${devstr}"
fi
