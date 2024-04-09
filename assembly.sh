#!/bin/bash

#install packet для сборки

# redhat-lsb-core \ Поддержка модулей Linux Standard Base (LSB) Core обеспечивает основные системные интерфейсы, библиотеки и среду выполнения, от которых зависят все соответствующие приложения и библиотеки.
# wget \
# rpmdevtools \ пакет содержит сценарии и файлы поддержки (X)Emacs, которые помогут в разработке пакетов RPM.
# rpm-build \
# createrepo \
# yum-utils \
# gcc  Коллекция компиляторов GNU (GCC) представляет собой совместимый со стандартами и легко переносимый компилятор ISO C и ISO C++

yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc


#NGINX и соберем его с поддержкой openssl

#Загрузим SRPM пакет NGINX

wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm


#При установке такого пакета в домашней директории создается древо каталогов для сборки:
rpm -i nginx-1.*

#скачать и разархивировать последний исходник для openssl - потребуется при сборке

wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip

#Разархивация в директорию openssl
unzip OpenSSL_1_1_1-stable.zip -d openssl/
mv  /home/vagrant/openssl/openssl-OpenSSL_1_1_1-stable/* /home/vagrant/openssl/

#поставим все зависимости, чтобы в процессе сборки не было ошибок
yum-builddep rpmbuild/SPECS/nginx.spec
#поправить сам spec файл, чтобы NGINX собирался с необходимыми нам опциями:
# --with-openssl=/root/openssl-1.1.1a
#sudo sed -i '115i\--with-openssl=/root/openssl' rpmbuild/SPECS/nginx.spec

sudo sed -i '114i\--with-openssl=/home/vagrant/openssl \\' rpmbuild/SPECS/nginx.spec
#приступить к сборке RPM

rpmbuild -bb rpmbuild/SPECS/nginx.spec

#+ /usr/bin/rm -rf /home/vagrant/rpmbuild/BUILDROOT/nginx-1.20.2-1.el8.ngx.x86_64
#+ exit 0
echo $?
#Убедимся, что пакеты создались

sudo ls rpmbuild/RPMS/x86_64/


#можно установить пакет и убедиться, что nginx работает
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm

systemctl start nginx
systemctl status nginx

echo ###################################
echo #DONE Собран свой пакет nginx c openssl
echo ####################################


nginx -V
#built with OpenSSL 1.1.1k  FIPS 25 Mar 2021

#Создаем свой репозиторий и разместим там ранее собранный RPM

sudo mkdir /usr/share/nginx/html/repo
#Скопируем репозиторий
sudo cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm  /usr/share/nginx/html/repo/

#добавим Percons Server
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm


#Инициализируем репозиторий командой:

createrepo /usr/share/nginx/html/repo/

#В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В
#результате location будет выглядеть так:
#location / {
#root /usr/share/nginx/html;
#index index.html index.htm;
#autoindex on; < Добавили эту директиву
#}


nginx -t 

nginx -s reload

curl -a http://localhost/repo/
#<html>
#<head><title>Index of /repo/</title></head>
#<body>
#<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
#<a href="repodata/">repodata/</a>                                          09-Apr-2024 08:25                   -
#<a href="nginx-1.20.2-1.el8.ngx.x86_64.rpm">nginx-1.20.2-1.el8.ngx.x86_64.rpm</a>                  09-Apr-2024 08:14#             2250712
#<a href="percona-orchestrator-3.2.6-2.el8.x86_64.rpm">percona-orchestrator-3.2.6-2.el8.x86_64.rpm</a>        16-Feb-2022# 15:57             5222976
#</pre><hr></body>
#</html>

#Добавим его в /etc/yum.repos.d

touch /etc/yum.repos.d/otus.repo
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

#Проверяем

 sudo repolist enabled | grep otus
 sudo yum list | grep otus
 sudo yum repolist all
 
 
yum install percona-orchestrator.x86_64 -y


#repo добавлен

#Все прошло успешно. В случае, если вам потребуется обновить репозиторий (а это
#делается при каждом добавлении файлов) снова, то выполните команду createrepo
#/usr/share/nginx/html/repo/

