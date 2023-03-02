#! /usr/bin/bash
# Barebones implementation of V.A.C.A.
# CPA 2023

######################### Imports ####################################

source vl.conf
source vl.telegram.example
# FINAL LOCATION
# source /opt/vaca-lite/vl.conf
# source /opt/vaca-lite/vl.telegram

######################### Global vars ################################

timestamp=$(date +%s)

######################### Call #######################################

parallel-ssh -h vl.clients  -o free  -i free > /dev/null 2> /dev/null 
# FINAL LOCATION
# parallel-ssh -h vl.clients  -o /opt/vaca-lite/free  -i free -h

######################### Eval #######################################

# FINAL LOCATION
# for f in /opt/vaca-lite/freei/*; do
for f in free/*; do
    pc=$(echo $f | sed 's/^.*\///')
    sshok=1
    ramok=1
    success=$(wc -l $f | cut -f 1 -d ' ')
    if [ $success -eq 0 ]; then
        sshok=0
    else
      cat $f | tr -s ' ' > free.tmp
      totmem=$(grep -i 'mem' free.tmp | cut -f 2 -d ' ')
      usemem=$(grep -i 'mem' free.tmp | cut -f 3 -d ' ')
      availablemem=$(grep -i 'mem' free.tmp | cut -f 7 -d ' ')
      totswa=$(grep -i 'swa' free.tmp | cut -f 2 -d ' ')
      useswa=$(grep -i 'swa' free.tmp | cut -f 3 -d ' ') 
      freswa=$(grep -i 'swa' free.tmp | cut -f 4 -d ' ')
      availableMemPerc=$(($availablemem *100 / $totmem)) # esta es la buena para saber cuanta memoria queda libre
      usedSwapPerc=$(($useswa *100 / $totswa)) # esta es para el porcentaje del swap libre
      rm free.tmp

        if [[ $availableMemPerc -lt $available_ram_limit  ||  $usedSwapPerc -gt $swap_limit ]]; then
            ramok=0
            echo "--------" >> $logs/$pc
            echo ">$timestamp" >> $logs/$pc
            cat $f >> $logs/$pc
            echo "--------"
            echo "RAM ALERT FOR $pc"
            echo "Used swap      = $usedSwapPerc%"
            echo "Available ram  = $availableMemPerc%"
        else
            # TODO
            # check for prev fail
            echo "--------"
            echo "$pc OK!"
        fi
    fi
done


######################### Notify #####################################

# URL="https://api.telegram.org/bot$KEY/sendMessage"
# ALERTMSG=$(/usr/games/cowsay  hola)
# TEXT="${USER} desde  $HOSTNAME dice: $ALERTMSG  :)"
# curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
# #
######################## Log ########################################
