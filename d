#!/bin/bash
######################################################################
#This script is to cancel IP input when login a lab 
# 2015/12/10 yidu First Release
# 2015/12/11 yidu combine: cancel pwd combined in this tool
# 2016/7/27  yidu optimize, make a single file to store lab info.Then
#            cancel the -c option when first time run this script.
# 2016.7/29  yidu enhance, if first time running, need input IP and user
# 2016/8/3   yidu enhance, open mutiple terminate in one time with assigned name.
######################################################################
host=""
dir=$(dirname $0)
function usage()
{
	echo -e "Usage: \t$0 \033[31mhostname\033[0m \033[34mtitle1\033[0m \033[34mtitle2\033[0m \033[34mtitle3\033[0m..."
	echo -e "\thostname: \033[31mRequired\033[0m. If first time execution, need input host and IP;"
	echo -e "\t\033[34me.g: ./d atca2\033[0m"
	echo -e "\ttitle: \033[34mOptional\033[0m, you can title your window or using a default one."
	echo -e "\t\033[34me.g: ./d atca2 subshl\033[0m"
	echo -e "\tIf no rsa_keys generated on your workstation before, you need:"
	echo -e "\tPrint enter for several times when ./d hostname"
	exit
}

function determine_ip()
{
  if [ -f "$dir/lab_info" ];then
     echo "lab_info found."
  else 
     echo "lab_info not found, which should placed in same dir with "d"!"
     exit
  fi
  cat $dir/lab_info | cut -d '|' -f 1 |grep -w $1 > /dev/null 2>&1
  if [ "$?" -eq "0" ]
  then 
       user=$(grep -w $1 $dir/lab_info | grep '^'$1'' | cut -d '|' -f 2)
       ip=$(grep -w $1 $dir/lab_info | grep '^'$1'' | cut -d '|' -f 3)
  else
       echo "Undefined hostname in "lab_info"! You need input it:"
       #read -p "Please Input the hostname you want to define: " -t 120 host
       read -p "Please input the username of your lab(ainet): " -t 120 user
       read -p "Please input the ip of your lab: " -t 120 ip
       if [ -z "user" -o -z "$ip" ];then
          echo "username, ip should not be null!"
          exit
       fi
       echo "$1|$user|$ip" >> $dir/lab_info
  fi
}
function cancel_pwd()
{
  #if public key exists in local:
  if [ -e ~/.ssh/id_rsa.pub -a -e ~/.ssh/id_rsa ];then
     echo "Found id_rsa.pub"
     pub_key=$(cat ~/.ssh/id_rsa.pub)
     pub_key_postfix=$(cat ~/.ssh/id_rsa.pub | cut -d ' ' -f 3)
     scp -o StrictHostKeyChecking=no $user@$ip:~/.ssh/authorized_keys ~/.ssh/id_rsa.pub.bk 2> /dev/null
     if [ $? -ne 0 ];then
        echo "authorized_keys file not found on remote host."
        mkdir -p ~/.ssh_temp/.ssh
        chmod 700 ~/.ssh_temp/.ssh
        cp ~/.ssh/id_rsa.pub ~/.ssh_temp/.ssh/authorized_keys
        echo "Copying authorized_keys to remote"
        scp -o StrictHostKeyChecking=no -r ~/.ssh_temp/.ssh $user@$ip:~/
        test $? -eq 0 && echo "authorized_keys file new completed." || echo " authorized_keys file new failed." 
        rm -r ~/.ssh_temp
                	
     else
        echo "authorized_keys file found."
        grep -w "$pub_key" ~/.ssh/id_rsa.pub.bk 1> /dev/null 
        if [ "$?" -eq "0" ];then
           echo "pub_key matched." 
        else
            #sed -i '/'$pub_key_postfix'/d' ~/.ssh/id_rsa.pub.bk
            cat ~/.ssh/id_rsa.pub.bk |sed 's/.*'$pub_key_postfix'$/ /g'|sed '/^$/d' > ~/.ssh/id_rsa.pub.bk.tmp
            mv ~/.ssh/id_rsa.pub.bk.tmp ~/.ssh/id_rsa.pub.bk
            echo ~/.ssh/id_rsa.pub.bk
       	    cat ~/.ssh/id_rsa.pub >> ~/.ssh/id_rsa.pub.bk
            echo "pub_key copied to remote."
       	    scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa.pub.bk $user@$ip:~/.ssh/authorized_keys 
       	    rm ~/.ssh/id_rsa.pub.bk
        fi
     fi
  #not exist in local
  else
     echo "~/.ssh/id_rsa.pub not found and have to be generated!"
     echo "Please print "Enter" for three times:"
     ssh-keygen -t rsa

     scp -o StrictHostKeyChecking=no $user@$ip:~/.ssh/authorized_keys ~/.ssh/id_rsa.pub.bk 2> /dev/null
     if [ $? -ne 0 ];then
        mkdir -p ~/.ssh_temp/.ssh
	chmod 700 ~/.ssh_temp/.ssh
       	cp ~/.ssh/id_rsa.pub ~/.ssh_temp/.ssh/authorized_keys
       	echo "Copying authorized_keys to remote"
       	scp -o StrictHostKeyChecking=no -r ~/.ssh_temp/.ssh $user@$ip:~/
       	rm -r ~/.ssh_temp
                	
     else
#       sed -i '/'$pub_key_postfix'/d' ~/.ssh/id_rsa.pub.bk
        cat ~/.ssh/id_rsa.pub.bk |sed 's/.*'$pub_key_postfix'$/ /g'|sed '/^$/d' > ~/.ssh/id_rsa.pub.bk.tmp
        mv ~/.ssh/id_rsa.pub.bk.tmp ~/.ssh/id_rsa.pub.bk
       	cat ~/.ssh/id_rsa.pub >> ~/.ssh/id_rsa.pub.bk
        scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa.pub.bk $user@$ip:~/.ssh/authorized_keys 
        rm ~/.ssh/id_rsa.pub.bk
     fi

  fi

}


function start()
{
  if [ "$#" -eq "1" ];then
      title=$1
      #xterm -n $title -e ssh -q -o StrictHostKeyChecking=no -l $user $ip &
      #gnome-terminal -t $title -x ssh -q -o StrictHostKeyChecking=no -l $user $ip &
      gnome-terminal -t $title -e "bash -c 'ssh -q -o StrictHostKeyChecking=no -l $user $ip;bash'"

  else
      shift
      for n in $*
      do
         title=$n
         #xterm -n $title -e ssh -q -o StrictHostKeyChecking=no -l $user $ip &
         gnome-terminal --title=$title -x ssh -q -o StrictHostKeyChecking=no -l $user $ip &
      done     
  fi
}
#### main starts here

if [ "$#" == "0" ]
then
	usage
fi

determine_ip $1
cancel_pwd 
start $*
