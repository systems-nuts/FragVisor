#! /bin/bash
#
# jack_ab.sh
# Copyright (C) 2020 jackchuang <jackchuang@echo>
#
# Distributed under terms of the MIT license.
#

set -u

# echo "for kk in `seq 10`; do echo -e "\n\n === $kk/10 ===\n\n"; time ./ab_micro_diff_sizes_lan.sh 1000_lan_from_echo; sleep 5; done"

usr_input_name="$1"
_log_name_prefix="ab_micro_all_0x2" # just in case
log_name_prefix=${_log_name_prefix}_${usr_input_name}
_project=pophype_ab_micro_diff_sizes_lan
project=`pwd`/${_project}

TSTAMP=`date +%Y%m%d_%T | sed 's/:/_/g'`
project_sub_folder=${project}/${_project}_${TSTAMP}_${log_name_prefix}
#mkdir -p ${project_sub_folder}

echo "================="
echo ""
echo "System: 4vcpu/2vcpu, must have only 1 Nginx worker"
echo ""
echo "e.g. ./ab_micro_diff_sizes_lan.sh ab_micro_net_1000_lan"
echo "e.g. ./ab_micro_diff_sizes_lan.sh 1000_lan_from_echo"
echo ""
echo "==="

###
CPU="0x2"
#CPU="0x1"
#CPU="0x2 0x1"
#CPU="0x1 0x2"
#CPU="0x1 0x2 0x4 0x8"
#

###
#########SIZE="1 2 " # kill me
SIZE="1 "
#SIZE=""
#

### This value = init value / 2#a=2 # ab request header is 229 Bytes
a=2 # ab request header is 229 Bytes
#1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864
#a=32


#a=256 # ab request header is 229 Bytes
#256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864

#a=16384
#a=65536
#a=131072
#262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864

#a=262144
#a=524288

#a=1048576
#1048576 2097152 4194304 8388608 16777216 33554432 67108864

#a=2097152

#a=16777216
#16777216 33554432 67108864

#a=67108864

#################3
#SIZE+="$a "
#SIZE+="4 4096"
#SIZE+="2 4 16 64 256 1024 4096 16384 65536 262144"
#SIZE+="2 4 16 64 256 1024 4096 16384 65536 262144 1048576 4194304 16777216 67108864" # Jack - remove me
#SIZE+="4194304 16777216 67108864" # Jack - remove me
SIZE+="2 4 16 64 256 1024 4096 16384 65536 262144 1048576" #4194304 16777216 67108864"
#SIZE+="2 4 16 64 256 1024 4096 16384 65536 262144" 
#SIZE="1048576"
#for i in `seq 1`; do
#for i in `seq 3`; do
#for i in `seq 15`; do # special
#for i in `seq 0`; do # one shot # test
#for i in `seq 2`; do # a=16777216
#for i in `seq 4`; do # a=4194304
#for i in `seq 5`; do # a=2097152
#for i in `seq 6`; do # a=1048576
#for i in `seq 7`; do # a=524288
#for i in `seq 19`; do # a=262144
#for i in `seq 9`; do # a=131072
#for i in `seq 10`; do # a=65536
#for i in `seq 13`; do # a=8192
#for i in `seq 18`; do # a=256
#for i in `seq 21`; do # a=32
#for i in `seq 25`; do # a=2
	#a=$( expr $a \* $a )
	#a=$( expr $a \* 2 )
	#SIZE+="$a "
#done
echo "$SIZE"

echo "default 229 bytes in the headers !!!!!!!!!!!!!! small bytes do not make sense"

for cpu in $CPU
do
	###
	rm output result
	#
	for size in $SIZE
	do
		########
		# main
		########
		#TSTAMP=`date +%Y%m%d_%T | sed 's/:/_/g'`
		#_project_sub_folder=${project}/${_project}_${TSTAMP}_${log_name_prefix}_${cpu}_${size}
		_project_sub_folder=${project}/${_project}_${TSTAMP}_${log_name_prefix}_${cpu}
		echo -e "out: ${_project_sub_folder}\n"
		mkdir -p ${_project_sub_folder}
		###########
		
		echo -e "======\n=== cpu: $cpu size: $size ===\n========\n" \
				| tee -a output | tee -a ${_project_sub_folder}/full_log

		# set cpu affinity - only for only NGNIX WORKER
		pid=`ssh root@10.4.4.222 ps aux | grep nobody | awk '{print $2}'`
		echo "got pid = $pid"
		echo "ssh root@10.4.4.222 taskset -p $cpu $pid"
		ssh root@10.4.4.222 taskset -p $cpu $pid
		echo "for me to verify: make sure there is only one worker. Otherwise, stop it!"
		ssh root@10.4.4.222 ps aux | grep nobody
		#pid=`ssh root@10.4.4.222 ps aux | grep $pid`
		echo "got pid and set cpu affinity done"

		## set cpu affinity - only for both NGNIX MASTER & WORKER
		#MASTER_ONE=$(ssh root@10.4.4.222 ps aux | grep nginx | head -n 1 | awk '{print$2}')
		#WORKER_ONE=$(ssh root@10.4.4.222 ps aux | grep nginx | tail -n 1 | awk '{print$2}')
		#MASTER_ONE_DBG=$(ssh root@10.4.4.222 ps aux | grep nginx | head -n 1)
		#WORKER_ONE_DBG=$(ssh root@10.4.4.222 ps aux | grep nginx | tail -n 1)
		#echo "$MASTER_ONE_DBG"
		#echo "$WORKER_ONE_DBG"
		#echo "$MASTER_ONE"
		#echo "$WORKER_ONE"
		#echo -e "\n\nBefore:"
		#ssh root@10.4.4.222 "taskset -p $MASTER_ONE" #(master)
		#ssh root@10.4.4.222 "taskset -p $WORKER_ONE" #(worker)
		#echo -e "\n\nModifying:"
		#ssh root@10.4.4.222 "taskset -p $cpu $MASTER_ONE" #(master)
		#ssh root@10.4.4.222 "taskset -p $cpu $WORKER_ONE" #(worker)
		#echo -e "\n\nAfter:"
		#ssh root@10.4.4.222 "taskset -p $MASTER_ONE" #(master)
		#ssh root@10.4.4.222 "taskset -p $WORKER_ONE" #(worker)

		### INSTALL configs (scp) ###
        echo -e "\n WATCHOUT overwriting confis in the guest VM\n" | tee -a output
        (scp ~/share/popcorn_hype/kvmtool_popcorn_hype/pophype_make_ramdisk/bin_src/nginx-1.16.1/html/index.html_${size}byte \
							root@10.4.4.222:/usr/local/nginx/html/index.html) \
															| tee -a output
        ret=$?
        if [[ $ret != 0 ]]; then
            echo "bad scp travel_list.blade.php $ret" | tee -a output
            exit -1
        fi

		ssh root@10.4.4.222 sync
		sleep 3

		################### RUN
		for i in `seq 1`; do echo -e "\n\n=====\n=== iter $i/1 ====\n========\n"; (ab -n 1000 -c 10 http://10.4.4.222/) | tee -a output | tee -a ${_project_sub_folder}/full_log; sleep 3; done
		# 5000		32M ok 64 1500 dead
		# 1000		may be the best
		# 100000 too long
		########################################################
		########################################################
		
		echo -e "\n\n NEXT data size (bytes) YO\n\n"
		cp output ${_project_sub_folder}
		echo "--- real time monitor - summary ---"
		echo "$SIZE" | tee -a result | tee realtime_result_incasecrash
		cat ${_project_sub_folder}/output |egrep "cpu:|Transfer rate" | tee -a realtime_result_incasecrash
		sleep 3
	done

	echo -e "\n\n NEXT cpu affinity YO\n\n"
        
	### SHOW RESULTS ###
	echo "$SIZE" | tee -a result
	echo -e "\nTransfer rate: XXX [Kbytes/sec] received" | tee -a result
	cat output |grep "Transfer rate" |awk '{print $3}' | tee -a result

	echo -e "\nTime taken for tests: XXX seconds" | tee -a result
	cat output |grep "Time taken for tests" |awk '{print $5}' | tee -a result

	echo -e "\nTime per request: XXX [ms] (mean, across all concurrent requests)" | tee -a result
	# Time per request:       118.201 [ms] (mean, across all concurrent requests)
	cat output |grep "all concurrent requests" |awk '{print $4}' | tee -a result
	###########

	### SAVE RESULTS ###
	cp output ${_project_sub_folder}
	cp result ${_project_sub_folder}
	echo -e "\nout: $_project_sub_folder"
	###########
done
echo -e "\n\n $0 ALL DONE\n\n"
