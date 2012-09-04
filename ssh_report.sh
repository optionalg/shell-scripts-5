#!/bin/bash
auth_log=file
temp_log=file1
to=`date +"%b %d %T"`
let from_in_seconds=`date +%s`-43200
from=`date -d @$from_in_seconds +"%b %d %T"`
>file1
>logs
read month day time < <(date "+%b %_d %T" -d "-12 hours"); awk -v m="$month" -v d="$day" -v t="$time" '$1 == m && $2 >= d && $3 >= t {p=1} p' $auth_log >>file1

echo "=====================" >> logs
echo "= ssh login summary =" >> logs
echo -e "= From $from=" >> logs
echo -e "=To $to=" >> logs
echo -e "=====================\n\n\n" >> logs


echo "=====================" >> logs
echo "= Login Attempts   =" >> logs
echo "=====================" >> logs
echo -e "Total Number of Attempts=" `cat $temp_log|wc -l` "\tSuccessful Attempts=" `cat $temp_log|grep -i Accepted|wc -l` "\tFailure Attempts=" `cat $temp_log|grep -i Failure|wc -l`"\n"
#######################
echo "=====================" >> logs
echo "= Login Successful =" >> logs
echo "=====================" >> logs
gawk 'BEGIN {

print " Date 		User 		IP ";

print "------ 		------ 		----" }'

cat $temp_log |grep -i Accepted | awk {'print $1, $2, $3, $9, $11'} >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs


echo "==================" >> logs
echo "= Login failures =" >> logs
echo "==================" >> logs
gawk 'BEGIN {

       print " Date User IP ";

 
      print "------ ------ ----" }'

cat $temp_log |grep -i Failure | awk {'print $1, $2, $3, $15, $14'} >> logs
echo "--------------------------------" >> logs
echo "================================" >> logs


/usr/bin/Mailx -s "Logs for $hostname" admin@oursite.com < logs
rm -f logs
