#! /bin/bash
#
# run_NPB.sh
# Copyright (C) 2021 jackchuang <jackchuang@echo5>
#
# Distributed under terms of the MIT license.
#


MACHINES=(echo5 echo4 echo0 echo1)
HOST_MACHINE="echo5"

echo "========== MACHINE INFO ============="
echo "$MACHINES"
echo -e "=====================================\n\n\n"

VM_IP="10.4.4.222"
SSH_VM_IP="root@10.4.4.222"

echo "README: "
echo -e "- this script can be ran from any machine on the network\n\n\n"
servers "uname -a"

TSTAMP=`date +%Y%m%d_%T | sed 's/:/_/g'`

# folder and prefix for file name
_project=`echo $0 | sed 's/.*auto_run_//g' |sed 's/\.sh//g' | sed 's/\.\///g'`
#_project=pophype_ngnix_dsm # folder and prefix for file name
echo "project name: $_project"
echo "==========================================="
echo "=== It's better to run on $HOST_MACHINE ==="
echo -e "===========================================\n\n\n\n"
echo
echo

echo "Generating log name"
_OUTPUT=`echo "${0}" | sed 's/\.sh//g' | sed 's/\.\///g'`
echo "\$_OUTPUT = $_OUTPUT"
OUTPUT="${_OUTPUT}_trace"
echo "\$output = $OUTPUT"
echo 
echo

project=`pwd`/${_project}
project_sub_folder=${project}/${TSTAMP}_${_project}_PH_LEMP_25_100_REQ_0_BYTES_NGINX #_${prefix}
_project_sub_folder=$project_sub_folder
echo "mkdir -p ${_project_sub_folder}"
echo 
echo
mkdir -p ${_project_sub_folder}

LOCAL_PW=`pwd`
suffix=""

scp -r /home/jackchuang/share/balvansh/php-script/* root@10.4.4.222:/var/www/travel_list/routes/


echo "======================================"
echo "     Running this on Guest VM"
echo -e "======================================\n\n\n\n"


echo "USAGE: $0 <LAST_CPU>"

#Set number of iterations 
iter=1

if [ -z "$1" ]
then
	echo "No argument supplied <\$1 iters> default = 1"
else
	iter=$1
fi

echo -e "\n\n=================="
echo "=== iter = $iter ="
echo "=================="

#pid=()
i=0

APP+="25"

#APP+="ep.B"
#Final test set
#APP+="ep.B bt.B lu.B sp.B ua.B cg.B ft.B is.C"
#cpu_number_to_map=(0x1 0x2 0x4 0x8)
#echo "using "cpu_number_to_map" to select the number of CPUs"

for iter in `seq $iter`
do
	for app in $APP
	do
		echo "FOR RESPONSE TIME ${app}: " | tee -a ${_project_sub_folder}/out
		ssh root@10.4.4.222 "cd /var/www/travel_list/routes; cp php-script-${app}ms.php web.php"

		for k in `seq 0 1 3`
		do
			echo -e "reset /proc/popcorn_stat on ${MACHINES[$k]}"
			ssh ${MACHINES[$k]} "echo > /proc/popcorn_stat"
		done
	
		#ssh $SSH_VM_IP "cd /dev/parsec-3.0/bin/; taskset -c 0-3 parsecmgmt -a run -p blackscholes -c gcc-hooks -i native" | tee -a ${_project_sub_folder}/out

		#ab -n 100 -c 10 http://10.4.4.222/ | grep "Time taken for tests" -A 20 | tee -a ${_project_sub_folder}/out 
		ab -n 100 -c 10 http://10.4.4.222/ > ${_project_sub_folder}/interm_out

		for k in `seq 0 1 3`
		do
			ssh ${MACHINES[$k]} "cat /proc/popcorn_stat" | \
				tee -a ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]}
			echo "${MACHINES[$k]}: " | tee -a ${_project_sub_folder}/out
			cat ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]} | \
				head -5 | tee -a ${_project_sub_folder}/out
			cat ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]} | \
				grep eptfault2 | tee -a ${_project_sub_folder}/out
			cat ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]} | \
			    grep mm | tee -a ${_project_sub_folder}/out
			cat ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]} | \
			    grep gva_user | tee -a ${_project_sub_folder}/out
			echo tee -a ${_project_sub_folder}/out
		done

		echo | tee -a ${_project_sub_folder}/out
		echo | tee -a ${_project_sub_folder}/out
		#echo "FOR RESPONSE TIME ${app}: " | tee -a ${_project_sub_folder}/out

		cat ${_project_sub_folder}/interm_out | grep "Time taken for tests" -A 9 | tee -a ${_project_sub_folder}/time_taken_out
	
		sleep 5
	done

done



: <<'END'
for itr in `seq $iter`
do
	for app in $APP
	do
		echo -e "\n\n\n##################################"
		echo "########### $app start ###########"
		echo -e "##################################\n\n\n"
		for last_cpu in `seq 2 1 2`  # 4 instances `seq 0 1 3` == output > 0 1 2 3 4 
		do
			################ running each application and collecting time########
			unset pid
			pid=()
			PIDS=""
			echo "##################################"
			echo "####$APP - [$app] $itr/$iter #####"
			echo "#####$app $last_cpu star t########"
			echo -e "##################################\n\n\n"

			for k in `seq 0 1 $last_cpu`
			do
				echo -e "reset /proc/popcorn_stat on ${MACHINES[$k]}"
				ssh ${MACHINES[$k]} "echo > /proc/popcorn_stat"
			done
			echo 
			#### START TIMER ####
			start=$(date +%s.%N)
			for j in `seq 0 1 $last_cpu`
			do
				cpu=${cpu_number_to_map[$j]}
				echo "/${app}.x.ser.van j $j to cpu_mask cpu $cpu"

				ssh $SSH_VM_IP taskset $cpu /${app}.x.ser.van > /dev/null &

				cur_pid=$!
				PIDS+="$cur_pid "
				echo "++ [$cur_pid] $PIDS"
				pid[$i]=$cur_pid
			done

			for n in `seq 0 1 $last_cpu`
			do
				echo "new: wait${nn}/$last_cpu pid ${pid[$nn]}"
				wait ${pid[$nn]}
			done

			#### END TIMER ####
			end=$(date +%s.%N)
			let "tmp = $last_cpu + 1"
			echo "$app $tmp instances " | tee -a ${_project_sub_folder}/out

			for k in `seq 0 1 $last_cpu`
			do
				
				ssh ${MACHINES[$k]} "cat /proc/popcorn_stat" | \
					tee -a ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]}
				echo "${MACHINES[$k]}: " | tee -a ${_project_sub_folder}/out
				cat ${_project_sub_folder}/full_log_${app}_${last_cpu}_${MACHINES[$k]} | \
					grep eptfault | tee -a ${_project_sub_folder}/out
			done


			echo "##################################"
			echo "########$app $last_cpu DONE ######"
			echo -e "##################################\n\n\n"

			runtime=$(python3.7 -c "print(${end} - ${start})")
			echo "= recap ="
			echo "$0 $1"
			echo "#seq 0 1 3 = 0 1 2 3 (4 iter)"
			#let "tmp = $last_cpu + 1"
			echo -e "\n============="
			echo "[$app] $last_cpu $tmp instances $ii/$iter"
			echo "$app $tmp instances " | tee -a ${_project_sub_folder}/output
			echo "time $runtime" | tee -a ${_project_sub_folder}/output
			echo -e "=============\n"
			echo -e "\n\n $app $last_cpu DONE (take a break)\n\n"
			sleep 5
		done
	done
	echo "[for parse] time $ii/$iter [for parse]" | tee -a ${_project_sub_folder}/output
done
END

echo -e "\n\n$0 ALL DONE\n\n"


