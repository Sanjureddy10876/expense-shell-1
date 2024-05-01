#!/bin/bash

source ./common.sh

check_root

echo "Please enter DB password:"
read -s mysql_root_password

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "installing mysql-server"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "enabling mysqld"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "starting mysqld"

#mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOGFILE
#VALIDATE $? "setting root password"

#Below code will be useful for idempotent nature

mysql -h db.santhosh78s.online -uroot -p${mysql_root_password} -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0]
then
    mysql_secure_installation --set-root-pass ${mysql_root_password} &>>$LOGFILE
    VALIDATE $? "MySQL root password setup"
else
    echo -e "MySQL root password is already setup...$Y SKIPPING $N"
fi