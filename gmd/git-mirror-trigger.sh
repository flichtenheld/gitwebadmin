#!/bin/sh
NOW=$(date "+%Y-%m-%d %H:%M:%S")
EXE=$(basename $0)
URL="git://git.intranet.astaro.de/$*"
echo "$NOW $EXE[$$]: $*" >> /var/git/mirror.log
echo $URL |nc -w 1 localhost 8023
