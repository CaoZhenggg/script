#Author: CaoZheng
#Date: 2016/12/05
#Function: 找出.sh文件，如果是dos格式就打印出来

FILES=$(find RMT_PATH -type f -name \*.sh)

if [ -f /tmp/find_dos_file.txt ]
then
    rm -f /tmp/find_dos_file.txt
fi

for f in $FILES
do
{
    file $f | grep 'CRLF' > /dev/null
    if [ $? = 0 ]
    then
        echo $f is a dos file! >> /tmp/find_dos_file.txt
    fi
}&
done
wait
