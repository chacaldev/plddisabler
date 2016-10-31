#!/bin/bash

if [ $# -lt 1 ]; then
	printf "./plddisabler.sh [ld-linux.so]\n"
	exit 0
fi

#get the decimal reference of file "/etc/ld.so.preload"
file_ref=$(grep -obUaP $(echo -n '/etc/ld.so.preload'|hexdump -e '"\\\x" /1 "%02X"') $1)

#format the reference
file_ref=$(echo $file_ref|awk -F: '{ print "obase=16;" $1  }'|bc)

#generate an array of file bytes
file_array=($(cat $1|hexdump -v -e '/1 "%02X" " "'))

#iterate over the array and find the lea that refers $file_ref
for index in ${!file_array[*]}
do
  if [ "${file_array[$index]}" = "48" ] && [ "${file_array[$index+1]}" = "8D" ]; then
    pointer="${file_array[$index+6]}${file_array[$index+5]}${file_array[$index+4]}${file_array[$index+3]}"
    hindex="$(echo $index|awk -F: '{ print "obase=16;" $1  }'|bc)"
    referer="$(echo "obase=16; $(echo "ibase=16; $pointer+$hindex+7"|bc)"|bc)"
    if [ "$referer" = "$file_ref" ]; then
      printf "$hindex\n"
    fi
  fi
done
 
exit 0
