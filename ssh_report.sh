#!/bin/bash
to=`date +"%b %d %T"`
let from_in_seconds=`date +%s`-43200
from=`date -d @$from_in_seconds +"%b %d %T"`
>file1
>logs
Logins=`read month day time < <(date "+%b %_d %T" -d "-12 hours"); awk -v m="$month" -v d="$day" -v t="$time" '$1 == m && $2 >= d && $3 >= t {p=1} p' /var/log/auth.log >>file1`

echo "=====================" >> logs
echo "= Successful logins =" >> logs
echo "=====================" >> logs
gawk 'BEGIN {

print " Date 		User 		IP ";

print "------ 		------ 		----" }'

cat file1 |grep -i Accepted | awk {'print $1, $2, $3, $9, $11'} >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs


echo "==================" >> logs
echo "= Login failures =" >> logs
echo "==================" >> logs
gawk 'BEGIN {

       print " Date User IP ";

 
      print "------ ------ ----" }'

cat file1 |grep -i Failure | awk {'print $1, $2, $3, $15, $14'} >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs

/usr/bin/Mailx -s "Logs for $hostname" admin@oursite.com < logs
rm -f logs
