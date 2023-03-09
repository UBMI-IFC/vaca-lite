#! /usr/bin/bash
# Barebones implementation of V.A.C.A.
# CPA 2023

######################### Imports ####################################

source /home/seisbio/vaca-lite/vl.conf
source /home/seisbio/vaca-lite/vl.telegram.example
# FINAL LOCATION
# source /opt/vaca-lite/vl.conf
# source /opt/vaca-lite/vl.telegram

######################### Global vars ################################

timestamp=$(date +%s)
notification=0 

######################### Global functions ###########################
checkPrevFailInterval()
{
    if [ -f $1 ]; then
        prevalert=$(grep "<ALERT>" $1 | wc -l)
        if [ $prevalert -eq 0 ]; then
          echo "9900000"
        else
          prevfail=$(grep "<ALERT>" $1 | sed 's/<ALERT>//' | tail -1)
          echo "$(($timestamp - $prevfail))"
        fi
      else
        echo "0"
      fi
}

checkCurrentFailTimes()
{
  if [ -f $1 ]; then
    wc -l $1 | cut -f 22 -d ' '
  else
    echo 0
  fi
}
######################### Call #######################################

parallel-ssh -h /home/seisbio/vaca-lite/vl.clients  -o /home/seisbio/vaca-lite/free  -i free > /dev/null 2> /dev/null
# FINAL LOCATION
# parallel-ssh -h vl.clients  -o /opt/vaca-lite/free  -i free -h

######################### Eval #######################################

# FINAL LOCATION
# for f in /opt/vaca-lite/freei/*; do
for f in /home/seisbio/vaca-lite/free/*; do
    pc=$(echo $f | sed 's/^.*\///')
    error=1
    success=$(wc -l $f | cut -f 1 -d ' ')
    logfile=$(echo $logs_directory/$pc)
    logwaitingfile=$(echo $logfile.wait)
    interval=$(checkPrevFailInterval $logfile)
    errortime=$(checkCurrentFailTimes $logwaitingfile)

    if [ $success -eq 0 ]; then
      echo "--------" >> out.tmp
      err_msg="NETWORK ALERT FOR $pc"
      echo $err_msg >> out.tmp
      error=0
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
            err_msg="RAM ALERT FOR $pc" 
            echo "--------" >> out.tmp
            echo "RAM ALERT FOR $pc" >> out.tmp
            echo "Used swap      = $usedSwapPerc%" >> out.tmp
            echo "Available ram  = $availableMemPerc" >> out.tmp
            error=0
        else
            echo "--------"
            echo "$pc OK!"
        fi
    fi

    if [ $error -eq 0 ]; then
            echo "--------" >> $logfile
      if [[ $interval -ge $notification_interval  ||  $interval -eq 0 ]]; then
        if [ $errortime -eq 0 ]; then
          echo "." > $logwaitingfile
          echo "<new-error>$timestamp" >> $logfile
        elif [ $errortime -ge $wait_for_notification ]; then
          echo "." >> $logwaitingfile
          echo "<ALERT>$timestamp" >> $logfile
          notification=1
        else
          echo "." >> $logwaitingfile
          echo "<wait>$timestamp" >> $logfile
        fi
      else
        echo "<log>$timestamp" >> $logfile
      fi
      echo $err_msg >> $logfile
      cat $f >> $logfile
    else
      if [ -f $logfile ]; then 
        grep -E  "<.*>" $logfile | tail -1 | grep "new-error" > /dev/null && oneTimeError="1" || oneTimeError="0"
      else
        oneTimeError="1"
      fi
echo "errortime $errortime"
echo "oneTimeError $oneTimeError"
      if [ "$errortime" != "0" ] && [ "$oneTimeError" != "0" ]; then
        notification=1
        echo "$pc has recovered from previous error :)" >> out.tmp
        rm $logwaitingfile
      fi
    fi
done
######################### Notify #####################################
if [ $notification -eq 1 ]; then
  URL="https://api.telegram.org/bot$KEY/sendMessage"
  ALERTMSG=$(cat out.tmp)
  curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=VACA SAY MOO" $URL > /dev/null
  curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$ALERTMSG" $URL > /dev/null
fi
######################## Cleaning######################################

if [ -f out.tmp ];then
  rm out.tmp
fi

echo $timestamp >> /home/seisbio/vaca-lite/iteration-counter.txt
