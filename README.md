## mysql-2-git-enc
# Инструкция по установке и настройке

## Сервер

На сервере был настроен git, и FTP-сервер.
Серверный скрипт 
Серверный конфиг

1. Для начала нужно создать структуру директорий на сервере
Например

```
foo
  |- tmp
  |- complete
  |- repo
```
tmp - домашняя директория фтп-пользователей, сюда загружаются все файлы
complete - недоступная для фтп-пользователей директория, куда перемещаются из tmp файлы ключей и распакованные архивы 
repo - собственно директория локального репозитория с деревом файлов

2. Выложить initialization vector в HEX-формате куда-нибудь в веб-доступ, если вам так будет удобно. Нам - удобно, потому что его легко менять и система продолжает работать. В планах есть генерация уникального разового IV для каждого архива. Но если хотите - его можно жестко задать в скриптах.

3. После того как создана структура директорий, надо установить (или настроить, если он уже установлен) incron (смотрите руководство для своей операционной системы) и настроить в нем мониторинг tmp вот такой записью
/foo/tmp IN_CLOSE_WRITE /path/to/db-to-repo-serv-enc-iv.sh $#
Таким образом как только открытый для записи файл в /foo/tmp был закрыт, выполнится db-to-repo-serv-enc-iv.sh. Обратите внимание на $#  - это имя файла с которым произошло наблюдаемое событие. Очень нужная штука в процессе распаковки и добавления в репозиторий!

4. Ну и напоследок – указать пару параметров в db-to-repo-serv-enc-iv.conf и убедится, что в db-to-repo-serv-enc-iv.sh указан правильный путь к конфигу напротив source.

Параметры которые надо указать в db-to-repo-serv-enc-iv.conf
TEMP_DIR - это tmp из описанной выше структуры
UPLOADED_DIR - это complete из описанной выше структуры
REPO_DIR - это repo из описанной выше структуры
BARE_REPO - удаленный репозиторий в формате user@server:repo.git
PRIVATE_KEY - путь к приватному ключу id_rsa для распаковки архива с одноразовым паролем 
MAIN_LOG - главный логфайл сервера, хранится постоянно 
TEMP_LOG - временный логфайл процесса распаковки и добавления в репозиторий, используется для отправки на почту
INCRON_FILE_NAME - не трогать, смотреть документацию по  incron если интересно что это
FTP_LOG - путь к лог файлу фтп, используется для отправки уведомлений, если в  temp_dir загрузили что-то странное 
MAIL_ADDR - почта для отправки уведомлений

5. chmod +x db-to-repo-serv-enc-iv.sh и готово.

6. Если вы хотите централизовано собирать бэкапа клиентских баз данных, создайте скрипт  db-collector.sh, который по очереди вызывает скрипты на клиентских серверах, пример файла: 
```
#!/bin/bash
echo "Project1"
sshpass -p 'superpass'  ssh -p 3389  user@google.com '/path/to/script/db-to-repo-client-enc.sh'
sleep 60
echo "Project2 - mysql"
ssh user@gov.ua '/path/to/script/db-mysql-2-remote-repo.sh'
sleep 60
echo "Project2 - elastic"
ssh user@gov.ua '/path/to/script/db-elstcsrch-2-remote-repo.sh'
sleep 60
echo "Project3 via php script"
wget  -qO --no-check-certificate https://site.us/dmpr/index.php?key=secretpass &>/dev/null
sleep 60
....
```

## Клиент

На клиентском сервере нужно сделать дамп базы, зашифровать openssl и отправить на ftp, соответственно на клиентской стороне должны быть инструменты для этого, чтобы клиентский скрипт выполнялся.
Для хостингов без ssh-доступа мы разработали php-вариант скрипта, выложим позже.

Переименовать db-to-repo-client-enc-iv.conf.example в db-to-repo-client-enc-iv.conf и разместить на клиентском сервере.
В файле  db-to-repo-client-enc-iv.conf заполнить параметры:

DB_CONFIG - путь к конфигурационному файлу сайта (зачем это надо - см. ниже)
SOURCE_DIR - папка где будет происходить таинство дампа и шифрования
DUMP_NAME - имя файла дампа БД, предлагаемый шаблон содержит: имя сайта — тип базы данных (mysql\mongo\elastic\etc) — имя базы — тип сайта (прод\препрод\тест\и т.д.) 
MIN_DUMP_SIZE - минимальный размер файла дампа в Мб, если получившийся дамп будет меньше этого размера, то процесс прервется и вы получите уведомление на почту
BACKUP_NAME - ЧПУ имя этого бекапа, используется в теме уведомления о слишком маленьком размере файла дампа
PUB_KEY - путь к файлу открытого ключа бекап-сервера
IV_URL - ссылка на страницу с initialization vector в HEX-формате, если у вас не используется - просто удалите эту переменную
IV - переменная использующаяся при шифровании, если  вы не будете использовать IV_URL, то просто укажите  initialization vector в HEX-формате здесь
MAIL_TO - почтовый адрес для алерта о слишком маленьком размере файла дампа
TEMP_LOG - временный лог процесса (я знаю что эта переменная практически не используется в клиентском скрипте и переехала туда ХЗ откуда, но возможно я добавлю больше журналирования, поэтому пусть будет)
FTP_USER, FTP_PASS, FTP_HOST - параметры FTP

Переменные ниже вполне очевидны сами по себе, но могут вызвать недоумение их предлагаемые в conf.example значения.

Дело в том, что в скриптах бекапа баз принципиально стараемся не использовать жестко заданные пароли. Намного надежнее получать их из конфигов сайта или /etc/mysql/debian.cnf. Поэтому вы можете пойти нашим путем и подобрать парсер параметров, или просто вбить имя базы, пользователя и пароль в клиентский скрипт db-to-repo-client-enc-iv.conf и удалить переменную DB_CONFIG
DB_NAME 
DB_USER
DB_PASS 
А где же DB_HOST? Его нету, потому что в большинстве случаев он не нужен, а если понадобится - его легко добавить прямо в клиентский скрипт db-to-repo-client-enc-iv.sh. Возможно в будущем добавим эту переменную в конфиг.

После того как вы указали все переменные в db-to-repo-client-enc-iv.conf, надо в файле db-to-repo-client-enc-iv.sh прописать путь к файлу конфига во второй строчке, напротив source 
И в принципе - все, можно делать chmod +x db-to-repo-client-enc-iv.sh и запускать

В результате, на бекап-сервере в папке /foo/tmp/ должны появиться два файла: зашифрованный архив с базой, и зашифрованный ключом пароль к архиву. Правда, если вы уже настроили incron и db-to-repo-serv-enc-iv, то появятся они там очень ненадолго, и сразу же будут перемещены\распакованы в /foo/complete/, а еще через пару секунд, единственным признаком завершившегося процесса, будет файл базы в /foo/repo/

Как писалось выше, для хостингов без ssh мы разработали php-скрипт бекапа совместимого с серверным скриптом - выложим в следующей части статьи.


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

