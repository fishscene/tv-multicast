#!/bin/bash
version=2021.01.20
#set -x
pid=0

#### https://stackoverflow.com/questions/41451159/how-to-execute-a-script-when-i-terminate-a-docker-container
#### https://www.linuxjournal.com/content/bash-trap-command
#Define cleanup procedure
function cleanup()
{
    printf "\n#####################################################################\n#####################################################################\n"
	printf "Container stop signal received, performing cleanup...\n"
	rm -rf /config/sap/$ADAPTERNUMBER-sap.cfg

  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
	printf "\n\n tv-multicast stopped successfully.\n"
  fi
}

trap 'cleanup' EXIT
#trap 'cleanup' SIGHUP
#trap 'cleanup' SIGQUIT
#trap 'cleanup' SIGABRT
#trap 'cleanup' SIGKILL
#trap 'cleanup' SIGTERM
#trap 'cleanup' SIGUSR1
#trap 'cleanup' SIGUSR2
trap 'cleanup' SIGINT


if [ "$PERFORMSCAN" = true ] ; then
  printf "\n#####################################################################\n#####################################################################\n"
  printf "\nCurrent Task: Scanning for channels.\n"
  rm -rf /config/scanresults/channels.txt
  w_scan -X -c US > /config/scanresults/channels.txt

  #### Format the channels for minisapserver. https://serverfault.com/questions/685697/multiple-commands-in-docker-cmd-directive
  printf "\nCurrent Task: Format channels for multicast streaming.\n"
  rm -rf /config/*.cfg
  i=0
  while IFS=":" read -r channelName frequency vsb unknown channel subChannel
    do
      ((i=i+1))

      if grep -Fxq "239.255.0.$i:1234 1 $subChannel #$channelName" /config/$frequency.cfg > /dev/null 2>&1
      then
        printf ""
      else
        echo "239.255.0.$i:1234 1 $subChannel #$channelName" >> /config/$frequency.cfg
      fi
  done < /config/scanresults/channels.txt


  #### Output Multicast address and Channel Name.
  printf "\n#####################################################################\n#####################################################################\n"
  printf "\nCurrent Task: Display information\n"
  printf "\nAvailable Adapters:\n$(ls /dev/dvb)\n"
  for f in $(find /config/*.cfg -printf "%f\n"); do
    printf "\n\n"
    printf '%s\n' "Frequency: ${f%.cfg}"
    printf " Multicast Address\tChannel Name\n ---------------------------------\n"
    while IFS="# :" read -r multicastAddress port KeepAlive subChannel channelName channelNamePart2
    do
	  printf " $multicastAddress:$port \t$channelName $channelNamePart2\n"  ##\n = new line. \t = tab (to help align text in columns)
    done < /config/$f
  done

  printf "\n\nDone scanning. If FREQUENCY was not specified, container will stop."
  #exit
fi
if [ ! -z "${FREQUENCY}" ] ; then
##########################################################################################################################
##########################################################################################################################
  #### Remove sap config file
  printf "\n#####################################################################\n#####################################################################\n"
  printf "\nCurrent Task: Removing sap config file.\n"
  rm -rf /config/sap/$ADAPTERNUMBER-sap.cfg

  #### Create SAP config file.
  printf "\nCurrent Task: Create /config/sap/$ADAPTERNUMBER-sap.cfg\n"
  until [ -f /config/$FREQUENCY.cfg ]; do
    >&2 printf "Scanning is not complete - sleeping\n"
    sleep 5
    done
  printf "Scanning is complete. Moving on.\n"

  for f in "/config/$FREQUENCY.cfg"; do
    while IFS="# :" read -r multicastAddress port KeepAlive subChannel channelName channelNamePart2
    do
      printf '[program]\n' >> /config/sap/$ADAPTERNUMBER-sap.cfg
      printf "type=rtp\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "name=$channelName $channelNamePart2\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "user=$NAME\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "machine=$(hostname)\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "site=$SITENAME\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "address=$multicastAddress\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
  	  printf "port=$port\n\n\n" >> /config/sap/$ADAPTERNUMBER-sap.cfg
    done < /config/$FREQUENCY.cfg
  done
  ##############
  ##############
  printf "\n#####################################################################\n#####################################################################\n"
  printf "\nCurrent Task: Starting multicast streams.\n"
  dvblast -a $ADAPTERNUMBER -f $FREQUENCY -b 6 -c /config/$FREQUENCY.cfg -m VSB_8 -e --delsys $DELIVERY &
  pid="$!"
  printf "dvblast PID: $pid"
  wait "$pid"
fi
