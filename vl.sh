#! /usr/bin/bash
# Barebones implementation of V.A.C.A.
# CPA 2023

######################### Imports ###################################

source vl.conf
source vl.telegram.example
# FINAL LOCATION
# source /opt/vaca-lite/vl.conf
# source /opt/vaca-lite/vl.telegram

######################### Call #######################################

parallel-ssh -h vl.clients  -o free  -i free -h
# FINAL LOCATION
# parallel-ssh -h vl.clients  -o /opt/vaca-lite/free  -i free -h

######################### Eval #######################################

# for f in /opt/vaca-lite/free/*; do
#     head $f
# done

for f in free/*; do
    wc -l
done


totmem=$((grep -i 'mem' free.tmp || echo "fail" ) | cut -f 2 -d ' ')
usemem=$((grep -i 'mem' free.tmp || echo "fail" ) | cut -f 3 -d ' ')
availablemem=$((grep -i 'mem' free.tmp || echo "fail")  | cut -f 7 -d ' ')
totswa=$((grep -i 'swa' free.tmp || echo "fail") | cut -f 2 -d ' ')
useswa=$((grep -i 'swa' free.tmp || echo "fail" ) | cut -f 3 -d ' ') # uso de swap
freswa=$((grep -i 'swa' free.tmp || echo "fail" )| cut -f 4 -d ' ')
rm free.tmp

# extra metrics
if [ $availablemem != "fail" ] && [ $totmem != "fail" ]; then
    availableMemPerc=$(($availablemem *100 / $totmem)) # esta es la buena para saber cuanta memoria queda libre
else
    availableMemPerc="fail"
fi

if [ $freswa != "fail" ] && [ $totswa != "fail" ]; then
    freeSwapPerc=$(($freswa *100 / $totswa)) # esta es para el porcentaje del swap libre
else
    freeSwapPerc="fail"
fi

######################### Notify #####################################

URL="https://api.telegram.org/bot$KEY/sendMessage"
ALERTMSG=$(/usr/games/cowsay  hola)
TEXT="${USER} desde  $HOSTNAME dice: $ALERTMSG  :)"
curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
######################### Log ########################################
