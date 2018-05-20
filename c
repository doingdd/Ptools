#!/bin/bash
## Simplify scp command, use alias name instead of IP, use the specific remote dir.
## input alias name and file you want to transfer.
function usage()
{
    echo -e "\nc is to simplify the scp input, use alias instead of boring IP"
    echo "$0 <server>[:dir] <file1/folder1> [file2/folder2]....."
    echo -e "Example:\n\t$0 hp14 /u/ainet/test ./tools"
    echo -e "\t$0 hp14:/timestendata/log CBIS.log"
    exit
}

[ "$#" -lt "2" ] && usage
. ${0%/*}/.common_func

## check if destination dir input with host name
hostname=$(echo $1|awk -F':' '{print $1}')
folder=$(echo $1|awk -F':' '{print $2}')

## use check_lab_info to cancel passwd and get IP
host=$(check_lab_info $hostname)
cancel_passwd $hostname
home=$(ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=3 $host "pwd")
folder=${folder:="$home/workplace"}
ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=3 $host "[ -d "$folder" ] || mkdir -p $folder"
check_rc $? "Check folder: $host:$folder"

## copy all the files input after $1, let scp judge whether they are real file or not.
shift
scp -o StrictHostKeyChecking=no -o ConnectTimeout=3 -r $* $host:$folder
check_rc $? "Files copy to $host:$folder"
