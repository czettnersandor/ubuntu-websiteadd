#!/bin/bash

echo Ubuntu WebsiteAdd 0.0.1
echo "  Created for Cohesion Digital"
echo "  by Sandor Czettner, 2017"

# In debug mode, no command will be executed, only output to stdout. 1 or 0
DEBUG=1
OUTPUT="/tmp/ubuntu-websiteadd.txt"
PASSWORD=$(</root/default-password.txt)

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

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
    command=${@-"echo No command specified"}
    if [[ $DEBUG == "1" ]]; then
        echo Debug mode $DEBUG
        echo "$command"
    else
        $(command)
    fi
}

# Username
dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Username" \
--inputbox "System username. Try to keep it under 10 characters." 10 60 2>$OUTPUT

respose=$?

name=$(<$OUTPUT)

case $respose in
    ${DIALOG_OK})
        command="useradd --user-group --groups www-data --home-dir /var/www/${name} --create-home -p ${PASSWORD} ${name}"
        execorecho "${command}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        exit 0
esac

# Database
dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Database users and databases, separated by new lines" \
--editbox $OUTPUT 10 60 2>$OUTPUT

names=$(<$OUTPUT)

echo "$names"

case $respose in
    ${DIALOG_OK})
        sql=""

        while read -r line; do
            sql+="GRANT USAGE ON *.* TO ${line}@localhost IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON ${line}.* TO ${line}@localhost;
FLUSH PRIVILEGES;
CREATE DATABASE \`${line}\`;

"
        done <<< "$names"

        execorecho "${sql}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        exit 0
esac

# Confirm SQL
echo "$sql" > /tmp/ubuntu-websiteadd-sql.txt
dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Please confirm SQL before executed. ESC to cancel." \
--textbox /tmp/ubuntu-websiteadd-sql.txt 40 70 2>$OUTPUT

respose=$?

name=$(<$OUTPUT)

case $respose in
    ${DIALOG_OK})
        command="echo HAHA"
        execorecho "${command}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        exit 0
esac
