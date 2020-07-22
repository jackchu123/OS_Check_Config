#!/bin/bash
#
# create data file
# config 
data_file=/tmp/os_data.txt
# deploy
[ -f /tmp/os_data.txt ] && echo  > $data_file
#####################
#######get CPU#######
#####################
function cpu_check(){
	echo '===Hardware==='
	echo '---CPU---'
	cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c|xargs echo 'cpu核数: '
	echo "   "
}
#####################
#######get Memory####
#####################
function memory_check(){
	echo '---Memory---'
	memory_size=`free -th|sed -n '2p'|awk -F' ' '{print $2}'`
	# administrator privileges 
	memory_type=`sudo dmidecode|grep Speed|grep Current|tail -n 1|awk -F' ' '{print $3}'`
	if [ "$memory_type" -ge "2000" ]
	then
		echo 'Memory Type: DDDR4'
		echo "Memory Size: $memory_size"
	else
		echo 'Memory Type: DDDR3'
		echo "Memory Size: $memory_size"
	fi
	echo "   "
}
#####################
#######get Disk######
#####################
function disk_check(){
	echo '---Disk---'
	lsblk |grep sda >> /dev/null
	if [ $? -eq 0 ]
	then
		disk_size=`lsblk |grep sda|sed -n '1p'|awk -F' ' '{print $4}'`
		echo "Disk Size: $disk_size"
	else
		disk_size=`lsblk |grep vda|sed -n '1p'|awk -F' ' '{print $4}'`
		echo "Disk Size: $disk_size"
	fi

	disk_type=`cat /sys/block/*/queue/rotational|tail -n 1`
	if [ $disk_type -eq 0 ]
	then
		echo 'Disk is SSD'
	else
		echo 'Disk is HDD'
	fi
	echo "   "
	# Swap
	echo '---Swap---'
	swap_mode=`free -th|sed -n "3,1p"|awk '{print $2}'`
	if [ "$swap_mode" == "0B" ]
	then
		echo 'Swap is off'
	else
		echo 'Swap is on'
	fi
}

#####################
#####get Sofrware####
#####################
function soft_check(){
	echo '===Sofrware=='
	# kernel
	uname -a |xargs echo 'Kernel: '
	echo "   "
	# limits
	cat /etc/security/limits.conf | grep -Ev "^$|[#;]" >> /dev/null
	if [ $? -ne 0 ]
	then
		echo 'Limit: Default limits'
	else
		cat /etc/security/limits.conf | grep -Ev "^$|[#;]" |xargs echo 'Limit:'
	fi
	echo "   "
	# selinux
	getenforce>>/dev/null
	if [ $? -eq 0 ]
	then
		getenforce | xargs echo 'Selinux: '
	else
		echo 'Selinux: Selinux Service Not Start'
	fi
	echo "   "
	# passwd user
	awk -F":" '{print $1}' /etc/passwd|wc -l|xargs echo 'user number: '
	echo "   "
	# ip_forward
	forward_mode=`sysctl -a|grep net.ipv4.ip_forward|sed -n "1,1p"|awk '{print $3}'`
	if [ "$forward_mode" == "0" ]
	then
		echo 'ip_forward is off'
	else
		echo 'ip_forward is on'
	fi
	echo "   "
	# system
	cat /etc/os-release|xargs echo 'System:'
	echo "   "
	
}

function main(){
	cpu_check >> $data_file 2>&1
	memory_check >> $data_file 2>&1
	disk_check >> $data_file 2>&1
	soft_check >> $data_file 2>&1
}

main