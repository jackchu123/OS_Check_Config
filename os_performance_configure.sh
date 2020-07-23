#!/bin/bash
#
##########################################
# ScriptName: os_performance_configure.sh#
# Description: Linux performance deploy  #  
##########################################
# config
datetime=$(date +%Y%m%d-%H-%M-%S-%N)
sysctl_file=/etc/sysctl.conf
limits_file=/etc/security/limits.conf
# deploy
## sysctl backup
function file_back(){
	sysctl -a >> $sysctl_file.$datetime
	cp $sysctl_file $sysctl_file.bak
	cp $limits_file $limits_file.bak
}
## deafult configure
function deafult_configure(){
	# backup
	file_back
	# limit config
	cat >> /etc/security/limits.conf <<-EOF 
		root soft nofile 655350
		root hard nofile 655350
		root soft nproc 655350
		root hard nproc 655350
		* soft nofile 655350
		* hard nofile 655350
		* soft nproc 655350
		* hard nproc 655350
	EOF
	# swap config
	swapoff -a
	# disable selinux
	setenforce 0
	sed -i '/SELINUX=/d' /etc/selinux/config
	sed -i '/# SELINUXTYPE/i\SELINUX=disabled' /etc/selinux/config
	# histroy config
	echo export HISTTIMEFORMAT=\"%F %T \" >> /root/.bashrc
	# linux file security
	chattr +i /etc/sudoers
	chattr +i /etc/shadow
	chattr +i /etc/passwd
	chattr +a /var/log/messages
	chattr +a /var/log/wtmp
}

function web_configure(){
	# backup
	file_back
	# deafult
	deafult_configure
	# web config
	modprobe nf_conntrack
	cat >> /etc/sysctl.conf <<-EOF
		# Nat forward
		net.ipv4.ip_forward=1
		# Socket
		net.core.somaxconn=4096
		net.core.optmem_max=81920
		# TCP
		net.ipv4.tcp_syncookies=1
		net.netfilter.nf_conntrack_max=655350
		net.ipv4.tcp_max_syn_backlog=8192
		net.ipv4.ip_local_port_range=1024 65000
		net.ipv4.tcp_max_tw_buckets=50000
		net.netfilter.nf_conntrack_tcp_timeout_established=1200
		net.ipv4.tcp_timestamps=1
		net.ipv4.tcp_tw_recycle=0
		net.ipv4.tcp_tw_reuse=1
		net.ipv4.tcp_fin_timeout=30
		# java
		vm.max_map_count=655360
	EOF
	# deploy
	sysctl -p
}

function rollback_confirure(){
	cp $sysctl_file.bak $sysctl_file
	cp $limits_file.bak $limits_file
}

function main(){
	echo -en "This os performance optimization script, please select current service\n"
	echo -en "\033[43m""(1) deafult_configure (2) web_configure (3) sql_configure (4) rollback_confirure:""\033[49m"
	read Num
	case $Num in
		1) 
		echo 'You select deafult_configure'
		deafult_configure
		;;
		2)
		echo 'You select web_configure'
		web_configure
		;;
		3)
		echo 'You select sql_configure'
		#sql_configure
		echo 'Waiting....'
		;;
		4)
		echo 'You select rollback_confirure'
		rollback_confirure
		;;
	esac
}

main