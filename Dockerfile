FROM ubuntu:20.04
STOPSIGNAL SIGINT
run apt-get update
run apt-get install software-properties-common -y
run add-apt-repository ppa:b-rad/kernel+mediatree+hauppauge -y
run apt-get update
run apt-get install linux-mediatree minisapserver screen w-scan dvb-apps dvblast -y
run apt-get upgrade -y
run apt-get autoremove -y
run apt-get autoclean -y
run mkdir /config
run mkdir /config/scanresults
run mkdir /config/sap
ADD tv-multicast_Exec.sh /
run chmod +x /tv-multicast_Exec.sh
ENTRYPOINT ["/tv-multicast_Exec.sh"]
