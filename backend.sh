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

echo "Please Enter DB password:"
read -s mysql_root_password

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

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodjs"

dnf module enable nodejs:20 -y &>>$LOGFILE

VALIDATE $? "enabling nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "installing nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0]
then 
    useradd expense &>>$LOGFILE
    VALIDATE $? "creating user expense"
else 
    echo -e "user expense already created.. $Y SKIPPING $N"
fi


mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip 
&>>$LOGFILE
VALIDATE $? "Downloading backend"

cd /app &>>$LOGFILE
rm -rf /app/* &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

unzip -o /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Unzipping backend"
 
npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "Copying backend service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemctl"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend service"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql"

mysql -h db.santhosh78s.online -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Importing schema"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting backend"
