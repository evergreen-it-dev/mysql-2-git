## mysql-2-git-enc

Автор: Андрей Мельниченко, Evergreen

Вопросы можно писать на support@evergreens.com.ua

# Инструкция по установке и настройке

Инструкция и описание на русском: https://habrahabr.ru/post/321342/

Общая схема работы: http://imgh.us/db2repo-server.svg



## Пример лога добавления файла
если добавление прошло с ошибкой, то соответствующий пункт будет ERROR а не SUCCESS

```
30-11-2016 aXKbCRW5siSFS5aYqK.enc.file has arrived
removing 6+ hours old uploaded files in /foo/tmp/, listed below
Wed Nov 30 12:25:46 EET 2016 SUCCESS
------------------------------
file.ext is .enc.file SUCCESS
------------------------------
keyfile for encrypted file found SUCCESS
------------------------------
checking keyfile integrity and get one-time password
keyfile integrity checking SUCCESS
------------------------------
decrypting encrypted file to /foo/complete/
.enc file has been decrypted SUCCESS
deleting unnesesarry aXKbCRW5siSFS5aYqK.otp.key from  /path/to/dir/complete/
Wed Nov 30 12:25:47 EET 2016 SUCCESS
deleting unnesesarry aXKbCRW5siSFS5aYqK.enc.file from  /path/to/dir//tmp/
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
checking compressed file integrity
gzip integrity checking OK
------------------------------
uploaded database is sitename-mysql-dbname-prod.sql
------------------------------
uncompress uploaded file
file unpacked SUCCESS
------------------------------
remove aXKbCRW5siSFS5aYqK.tar.gz after unpack
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
get remote repo
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
remove old dump from local repo
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
moving uploaded file to local repo dir
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
commit DB file to local repo
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
git push to remote repo
Wed Nov 30 12:25:47 EET 2016 SUCCESS
------------------------------
Wed Nov 30 12:25:47 EET 2016 adding sitename-mysql-dbname-prod.sql to user@domain.com:reponame.git SUCCESS
------------------------------
```

## Пример лога уведомления о постороннем файле (взят общий лог сервера)

```
02-12-2016 1j23hk1jh3o.jpg has arrived
removing 6+ hours old uploaded files in /foo/tmp/, listed below
Fri Dec  2 16:26:14 EET 2016 SUCCESS
------------------------------
file.ext is NOT .otp.key or .enc.file
removing the bullshit file  1j23hk1jh3o.jpg
Fri Dec  2 16:26:14 EET 2016 SUCCESS
------------------------------
Fri Dec 02 15:53:20 2016 0 ::ffff:95.67.95.254 41725 /some/dir/here/fail-cover.jpg b _ i r user ftp 0 * c
Fri Dec 02 15:53:48 2016 0 ::ffff:95.67.95.254 23962  /some/dir/here/checklist_prev.png b _ i r user ftp 0 * c
Fri Dec 02 16:11:07 2016 0 ::ffff:95.67.95.254 38908  /some/dir/here/concept/design-6.png b _ i r user ftp 0 * c
Fri Dec 02 16:12:21 2016 0 ::ffff:95.67.95.254 14017  /some/dir/here/stats_cover.png b _ i r user ftp 0 * c
Fri Dec 02 16:26:14 2016 0 ::ffff:46.219.221.132 99470 /foo/tmp/1j23hk1jh3o.jpg b _ i r user ftp 0 * c
```

##Previos instruction

use it with incron, for automatically adding mysql dump to git repository

you need to upload two files  
file with one-time password inside filename.otp.key, which encrypted with open rsa key  
and file with sql dump in encrypted with OTP tar.gz archive inside filename.enc.file 

you need three directory  
tmp - for files in process of uploading  
complete - for key files   
repo - for repository with worktree

after IN_CLOSE_WRITE event happened in tmp directory, script will start and make all magic  
incrontab must contain something like  
/path/to/dir/DB-repo/tmp/ IN_CLOSE_WRITE /path/to/db-to-repo.sh $#  
where $# - sends filename to script as ${INCRON_FILE_NAME}

