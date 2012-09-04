#!/bin/bash
Accepted=`read month day time < <(date "+%b %_d %T" -d "-12 hours"); awk -v m="$month" -v d="$day" -v t="$time" '$1 == m && $2 >= d && $3 >= t {p=1} p' /var/log/auth.log | grep -i "Accepted"`
Failure=`read month day time < <(date "+%b %_d %T" -d "-12 hours"); awk -v m="$month" -v d="$day" -v t="$time" '$1 == m && $2 >= d && $3 >= t {p=1} p' /var/log/auth.log |grep -i "Failure"`

echo "=====================" > logs
echo "= Successful logins =" >> logs
echo "=====================" >> logs
gawk 'BEGIN {

       print " Date          User          IP ";

       print "------       ------        ----" }

cat "$Accepted" | awk {'print $1, $2, $3, $9, $11'}` >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs


echo "==================" >> logs
echo "= Login failures =" >> logs
echo "==================" >> logs
gawk 'BEGIN {

       print " Date          User          IP ";

       print "------       ------        ----" }

cat "$Failure" | awk {'print $1, $2, $3, $15, $14'}` >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs

/usr/bin/Mailx -s "Logs for $hostname" admin@oursite.com < logs
rm -f logs

