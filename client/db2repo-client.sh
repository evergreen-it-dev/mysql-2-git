#!/bin/bash
source /full/path/to/db-to-repo-client-enc-iv.conf
################################################
#dumping database
echo "`date` mysqldump ${DB_NAME}" >> ${TEMP_LOG}
cd ${SOURCE_DIR} && ${MYSQLDUMP} -u${DB_USER} -p${DB_PASS} --skip-extended-insert --add-drop-database --events ${DB_NAME} > ${DUMP_NAME}
cd ${SOURCE_DIR} &&  tar -zcvf ${ARCH_NAME}.tar.gz -C  ${SOURCE_DIR} ${DUMP_NAME}
#checking database dump size
DUMP_SIZE_CNTRL=$(echo "`du -m ${SOURCE_DIR}${DUMP_NAME} | awk '{ print $1}'`")
if [ ${DUMP_SIZE_CNTRL} -le ${MIN_DUMP_SIZE}  ]
then
    echo "ERROR - dump size is ${DUMP_SIZE_CNTRL}Mb, it's too low!" | mail -s "ERROR on ${BACKUP_NAME}" ${MAIL_TO}
    exit
else
    echo "dump is ${DUMP_SIZE_CNTRL}Mb"
fi
###
#cd ${SOURCE_DIR} && /usr/bin/openssl enc -aes-256-cbc -salt -k ${PASSWD} -in ${ARCH_NAME}.tar.gz -out ${ARCH_NAME}.enc.file
cd ${SOURCE_DIR} && ${OPENSSL} enc -aes-256-cbc -salt -K ${PASSWD} -iv ${IV} -in ${ARCH_NAME}.tar.gz -out ${ARCH_NAME}.enc.file
cd ${SOURCE_DIR} && echo ${PASSWD} > ${ARCH_NAME}
cd ${SOURCE_DIR} && ${OPENSSL} rsautl -encrypt -inkey ${PUB_KEY} -pubin -in ${ARCH_NAME} -out ${ARCH_NAME}.otp.key
#upload all files
cd ${SOURCE_DIR}
$FTP -n ${FTP_HOST} <<END_SCRIPT
quote USER ${FTP_USER}
quote PASS ${FTP_PASS}
put ${ARCH_NAME}.otp.key
quit
END_SCRIPT
$FTP -n ${FTP_HOST} <<END_SCRIPT
quote USER ${FTP_USER}
quote PASS ${FTP_PASS}
put  ${ARCH_NAME}.enc.file
quit
END_SCRIPT
#rm all files
rm ${TEMP_LOG}
rm ${SOURCE_DIR}${ARCH_NAME}*
rm ${SOURCE_DIR}${DUMP_NAME}
