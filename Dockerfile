FROM ubuntu:20.04
STOPSIGNAL SIGINT
run apt-get update && apt-get install software-properties-common -y && add-apt-repository ppa:b-rad/kernel+mediatree+hauppauge -y && apt-get update && apt-get install linux-mediatree minisapserver screen w-scan dvb-apps dvblast -y && apt-get upgrade -y && apt-get autoremove -y && apt-get autoclean -y
run mkdir /config && mkdir /config/scanresults && mkdir /config/sap
ADD tv-multicast_Exec.sh /
run chmod +x /tv-multicast_Exec.sh
ENTRYPOINT ["/tv-multicast_Exec.sh"]
