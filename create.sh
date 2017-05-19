#!/bin/bash

echo Ubuntu WebsiteAdd 0.0.1
echo "  Created for Cohesion Digital"
echo "  by Sandor Czettner, 2017"

# In debug mode, no command will be executed, only output to stdout 1 or 0
DEBUG=1
OUTPUT="/tmp/ubuntu-websiteadd.txt"
PASSWORD=$(cat /root/default-password.txt)

# cleanup  - add a trap that will remove $OUTPUT
# if any of the signals - SIGHUP SIGINT SIGTERM it received.
trap "rm $OUTPUT; exit" SIGHUP SIGINT SIGTERM

if [[ $DEBUG == "1" ]]; then
    echo Debug mode $DEBUG
    sleep 1
fi

# Execute or echo (see DEBUG)
#  $1 -> command to execute
function execorecho(){
    command n=${@-"echo No command specified"}
    if [[ $DEBUG == "1" ]]; then
        echo Debug mode $DEBUG
        echo $command
    else
        $(command)
    fi
}

dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Username" \
--inputbox "System username. Try to keep it under 10 characters." 10 60 2>$OUTPUT

respose=$?

name=$(<$OUTPUT)

case $respose in
    0)
        command="useradd --user-group --groups www-data --home-dir /var/www/${name} --create-home -p ${PASSWORD} ${name}"
        execorecho ${name}
        ;;
    1)
        echo "\nCancel pressed."
        exit 0
        ;;
    255)
        echo "\n[ESC] key pressed."
        exit 0
esac
