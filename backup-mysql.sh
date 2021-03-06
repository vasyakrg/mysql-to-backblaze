#!/bin/bash

cd "${BASH_SOURCE[0]%/*}"

# Set env
BACKUP_DIR="/var/backup_blaze/db"
DATE=`date +%Y-%m-%d_%H%M`

if [[ ! -d ${BACKUP_DIR} ]]; then
    mkdir -p ${BACKUP_DIR}
fi

if [[ ! -f .env ]]; then
    cp .env.example .env
    exit 1
fi

source .env

if [[ $(grep -r .env -e 'MYSQL_USER=') == '' ]]; then
    echo "Put credentions to .env"
    exit 1
fi

IFS=$'\r\n' command eval "BASES=($(mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'show databases;' -B))"

for BASE in ${BASES[*]}
  do
    if [ ${BASE} == "Database" ]; then
        continue
    fi

    if [ ! -d ${BACKUP_DIR}/${BASE} ]; then
      mkdir -p ${BACKUP_DIR}/${BASE}
    fi
    FILE=${BACKUP_DIR}/${BASE}/${BASE}_dump_${DATE}.sql.gz
    echo "<<< mysqlmump $FILE"
    mysqldump --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --host=localhost --routines ${BASE} | gzip -c > $FILE
  done

find ${BACKUP_DIR}/ -type f -mtime +${ROTATION} -delete


[[ ${BACKUP_REMOTE} == "true" ]] &&
for BASE in ${BASES[*]}
    do
        b2 sync ${DB_BACKUP_DIR}/${BASE} b2://hosting-amegaserver-com/${BASE}
    done

echo ">>> backup end: $DATE" >> ${DB_BACKUP_DIR}/log.out

exit 0
