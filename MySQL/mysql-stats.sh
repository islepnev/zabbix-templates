#!/bin/bash
### OPTIONS VERIFICATION
if [ -z "$1" -o -z "$2" ]; then
 echo "Usage: $(basename $0) \"none\" <metric> [username] [password]" >&2
 exit 1
fi

##### PARAMETERS #####
RESERVED="$1"
METRIC="$2"
if [ -n "$3" ]; then
    USER="--user=$3"
fi
if [ -n "$4" ]; then
    PASS="--password=$4"
fi
#
MYSQLADMIN="/usr/bin/mysqladmin"
MYSQL="/usr/bin/mysql"
##### RUN #####
if [ $METRIC = "json" ]; then
 result=`$MYSQLADMIN $USER $PASS extended-status | sed -e 's/|//g; /^+---/d' | awk '{print "\"" $1 "\":\"" $2 "\","}'`
 if [ -z "$result" ]; then
   exit 1
 fi
 echo "{"
 echo "$result"
 echo '"":""' # no trailing comma
 echo "}"
 exit 0
fi
if [ $METRIC = "alive" ]; then
 $MYSQLADMIN $USER $PASS ping | grep alive | wc -l
 exit 0
fi
if [ $METRIC = "version" ]; then
 $MYSQL -V | sed -e 's/^.*\(ver.*\)$/\1/gI'
 exit 0
fi

FILECACHE="/tmp/zabbix.mysql.cache"
TTLCACHE="25"
TIMENOW=`date '+%s'`
if [ -s "$FILECACHE" ]; then
 TIMECACHE=`stat -c"%Z" "$FILECACHE"`
else
 TIMECACHE=0
fi
if [ "$(($TIMENOW - $TIMECACHE))" -gt "$TTLCACHE" ]; then
 echo "" >> $FILECACHE # !!!
 DATACACHE=`$MYSQLADMIN $USER $PASS extended-status` || exit 1
 echo "$DATACACHE" > $FILECACHE # !!!
fi
#
cat $FILECACHE | grep -iw "$METRIC" | cut -d'|' -f3
#
exit 0
