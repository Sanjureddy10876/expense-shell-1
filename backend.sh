#!/bin/bash

# Source common functions
source ./common.sh

# Check if script is run as root
check_root || exit 1

# Disable existing Node.js module
dnf module disable nodejs -y &>> "$LOGFILE" || VALIDATE $? "Disabling Node.js module"

# Enable Node.js module version 20
dnf module enable nodejs:20 -y &>> "$LOGFILE" || VALIDATE $? "Enabling Node.js module"

# Install Node.js
dnf install nodejs -y &>> "$LOGFILE" || VALIDATE $? "Installing Node.js"

# Check if user 'expense' exists
id expense &>> "$LOGFILE"
if [ $? -ne 0 ]; then
    # Create user 'expense' if it doesn't exist
    useradd expense &>> "$LOGFILE" || VALIDATE $? "Creating user 'expense'"
else
    echo -e "User 'expense' already created. Skipping."
fi

# Create directory /app if it doesn't exist
mkdir -p /app &>> "$LOGFILE" || VALIDATE $? "Creating directory /app"

# Download backend code
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> "$LOGFILE" || VALIDATE $? "Downloading backend code"

# Extract backend code to /app
cd /app &>> "$LOGFILE" || VALIDATE $? "Changing directory to /app"
rm -rf /app/* &>> "$LOGFILE" || VALIDATE $? "Removing existing files in /app"
unzip -o /tmp/backend.zip &>> "$LOGFILE" || VALIDATE $? "Unzipping backend code"

# Install Node.js dependencies
npm install &>> "$LOGFILE" || VALIDATE $? "Installing Node.js dependencies"

# Copy systemd service file
cp /home/ec2-user/expense-shell-1/backend.service /etc/systemd/system/backend.service &>> "$LOGFILE" || VALIDATE $? "Copying systemd service file"

# Reload systemd daemon
systemctl daemon-reload &>> "$LOGFILE" || VALIDATE $? "Reloading systemd daemon"

# Start backend service
systemctl start backend &>> "$LOGFILE" || VALIDATE $? "Starting backend service"

# Enable backend service to start on boot
systemctl enable backend &>> "$LOGFILE" || VALIDATE $? "Enabling backend service"

# Install MySQL
dnf install mysql -y &>> "$LOGFILE" || VALIDATE $? "Installing MySQL"
# Import MySQL schema and log any errors
mysql -h db.santhosh78s.online -uroot -p"${mysql_root_password}" < /app/schema/backend.sql &>> "$LOGFILE" || { 
    VALIDATE $? "Importing MySQL schema"
    exit 1
}

# Restart backend service
systemctl restart backend &>> "$LOGFILE" || VALIDATE $? "Restarting backend service"
