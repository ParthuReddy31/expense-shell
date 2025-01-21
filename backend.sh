#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y  &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default Nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE_NAME
VALIDATE $? "Enabling -Nodejs version-20"

dnf install nodejs -y  &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nodejs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense   &>>$LOG_FILE_NAME
    VALIDATE $? "Adding Expense User"
else
    echo -e "User expense is already exist.. $Y Skipping $N"
fi

mkdir -p /app  &>>$LOG_FILE_NAME
VALIDATE $? "Creating app Directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Backend code"

cd /app

rm -rf /app/*
VALIDATE $? "Removing Old Code"

unzip /tmp/backend.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping The Code"

npm install  &>>$LOG_FILE_NAME
VALIDATE $? "Installing Dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#Preparing MySQL Schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.parthudevops.space -uroot -pExpenseApp@1 < /app/schema/backend.sql  &>>$LOG_FILE_NAME
VALIDATE $? "setting up transcations schema and table"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reloading"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling the Backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting the Backend"

systemctl restart backend
VALIDATE $? "Restarting the Backend"
