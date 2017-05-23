#!/bin/bash

echo Ubuntu WebsiteAdd 0.0.1
echo "  Created for Cohesion Digital"
echo "  by Sandor Czettner, 2017"

# In debug mode, no command will be executed, only output to stdout. 1 or 0
DEBUG=0
OUTPUT="/tmp/ubuntu-websiteadd.txt"
OUTPUT_TMP="/tmp/ubuntu-websiteadd.tmp"
OUTPUT_CONF="/tmp/ubuntu-websiteadd.conf"
PASSWORD=$(</root/default-password.txt)
MYSQL_ROOT=$(</root/mysql-root-password.txt)

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

# cleanup  - add a trap that will remove $OUTPUT
# if any of the signals - SIGHUP SIGINT SIGTERM it received.
trap "rm $OUTPUT; rm $OUTPUT_TMP; rm $OUTPUT_CONF; exit" SIGHUP SIGINT SIGTERM

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
        eval command
    fi
}

# Exit gracufully
function graceful_exit(){
    rm $OUTPUT;
    rm $OUTPUT_TMP;
    rm $OUTPUT_CONF
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
--editbox $OUTPUT 10 60 2> $OUTPUT_CONF

names=$(<$OUTPUT_CONF)

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
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        graceful_exit
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        graceful_exit
        exit 0
esac

# Confirm SQL
echo "$sql" > $OUTPUT_TMP
dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Please confirm SQL before executed." \
--editbox $OUTPUT_TMP 40 70 2> $OUTPUT_CONF

respose=$?

case $respose in
    ${DIALOG_OK})
        command="mysql -u root -p${MYSQL_ROOT} < ${OUTPUT_CONF}"
        execorecho "${command}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        graceful_exit
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        graceful_exit
        exit 0
esac

# Apache virtualhost
apache_vhost="<VirtualHost *:80>
    ServerAdmin support@cohesiondigital.co.uk
    DocumentRoot /var/www/${name}/data
    ServerName ${name}.cohesiondigital.co.uk
    ErrorLog \${APACHE_LOG_DIR}/${name}.cohesiondigital.co.uk-error_log
    CustomLog \${APACHE_LOG_DIR}/${name}.cohesiondigital.co.uk-access_log common
    <Directory /var/www/${name}/data/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Order allow,deny
        Allow from all
    </Directory>

    <FilesMatch \".+\.ph(p[3457]?|t|tml)$\">
        SetHandler \"proxy:unix:/run/php/php7.0-fpm-${name}.sock|fcgi://localhost\"
    </FilesMatch>
</VirtualHost>
"

echo "$apache_vhost" > $OUTPUT_TMP

dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Confirm /etc/apache2/sites-available/${name}.conf" \
--editbox $OUTPUT_TMP 40 70 2> $OUTPUT_CONF

respose=$?

case $respose in
    ${DIALOG_OK})
        command="cp ${OUTPUT_CONF} /etc/apache2/sites-available/${name}.conf; a2ensite ${name}"
        execorecho "${command}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        graceful_exit
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        graceful_exit
        exit 0
esac

fpm_config="[${name}]

user = ${name}
group = www-data

listen = /var/run/php/php7.0-fpm-${name}.sock

pm = ondemand

pm.max_children = 4

listen.owner = www-data
listen.group = www-data
"

echo "$fpm_config" > $OUTPUT_TMP

dialog --backtitle "Ubuntu WebsiteAdd" \
--title "Confirm /etc/php/7.0/fpm/pool.d/${name}.conf" \
--editbox $OUTPUT_TMP 40 70 2> $OUTPUT_CONF

respose=$?

case $respose in
    ${DIALOG_OK})
        command="cp ${OUTPUT_CONF} /etc/php/7.0/fpm/pool.d/${name}.conf"
        execorecho "${command}"
        ;;
    ${DIALOG_CANCEL})
        echo "Cancel pressed."
        graceful_exit
        exit 0
        ;;
    ${DIALOG_ESC})
        echo "[ESC] key pressed."
        graceful_exit
        exit 0
esac

echo ""
echo "All configuration has been saved. Restart php-fpm and reload apache configuration:"
echo ""
echo "sudo service php-fpm restart"
echo "sudo service apache2 reload"
graceful_exit
