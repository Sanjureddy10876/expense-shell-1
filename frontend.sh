#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" .sh)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
P="\e[35m"
C="\e[36m"
W="\e[37m"
N="\033[0m"


VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILED $N"
        exit 1 
    else 
        echo -e "$2....$G SUCCESS $N"
    fi
}
if [ $USERID -ne 0 ]
then 
    echo "Please run this script with root access."
    exit 1 #manuvally exit if error comes
else
    echo "You are the super user."
fi

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabiling Ngnix"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing Exiting content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE 
VALIDATE $? "Downloading Frontend Code"

cd /usr/share/nginx/html &>>$LOGFILE
unzip -o /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Unzipping Frontend Code"

#check your repo and path
cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting Nginx"

