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

echo "script started Executing at : $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install mysql-server -y  &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld  &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MySQL server"

systemctl start mysqld  &>>$LOG_FILE_NAME
VALIDATE $? "Starting MySQL server"

mysql -h mysql.parthudevops.space -u root -pExpenseApp@1 -e 'show databases;'   &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
    echo -e "$Y MySQL Root Password not setup $N" &>>$LOG_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting Root Password"
else
    echo -e "$G MySQL Root password already setup ... $Y SKIPPING $N"
fi

echo "--------"
echo $( ps -ef | grep mysqld )
echo "--------"
echo $(netstat -lntp)