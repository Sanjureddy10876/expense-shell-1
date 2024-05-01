#!/bin/bash

source ./common.sh

check_root

echo "Please enter DB password:"
read -s mysql_root_password

dnf install mysql-serffver -y &>>$LOGFILE

systemctl enable mysqld &>>$LOGFILE

systemctl start mysqld &>>$LOGFILE

#Below code will be useful for idempotent nature

mysql -h db.santhosh78s.online -uroot -p${mysql_root_password} -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0]
then
    mysql_secure_instaddsllation --set-root-pass ${mysql_root_password} &>>$LOGFILE
    VALIDATE $? "MySQL root password setup"
else
    echo -e "MySQL root password is already setup...$Y SKIPPING $N"
fi