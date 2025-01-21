#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e " $2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e " $R ERROR:: To Install any Package USER should be ROOT"
        exit 1
    fi
}

mkdir -p /var/log/expense-logs

echo "script started Executing at : $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE_NAME
VALIDATE $? "Removing Default HTML Pages"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Frontend Code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML Directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping Frontend Code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting Nginx"

echo " --------------------"
echo $(ps -ef | grep nginx)
echo " --------------------"
echo $(netstat -lntp)
