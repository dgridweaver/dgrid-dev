#!/bin/bash

# hoststat "pingpong" driver of host/node status

#################

hoststat_pingpongsrv_simple()
{
echo `status_print_string_short`" : hoststat_pingpongsrv_simple"
while read inp; do
#echo inp=$inp
if [ "x$inp" == x"ping" ]; then
echo "pong"
fi

if [ "x$inp" == x"exit" ]; then
exit
#echo "pong"
fi

done
}

hoststat_emit_ping()
{
local hoststat_pingpong_timeout=2
while test 1 ; do 
echo "ping"
sleep $hoststat_pingpong_timeout
done
}

hoststat_recieve_pong()
{
while read inp; do
#echo inp=$inp
echo "get: $inp"
if [ "x$inp" == x"pong" ]; then
echo "status: ONLINE"
fi
done
}

hoststat_pingpong_cicle_simple()
{
local nodeid=$1
#dgridsys_cli_main run nodecli $nodeid ./dgrid/modules/hoststat/pingpong-srv.sh
hoststat_emit_ping | dgridsys_cli_main run nodecli $nodeid ./dgrid/modules/hoststat/pingpong-srv.sh | hoststat_recieve_pong
}