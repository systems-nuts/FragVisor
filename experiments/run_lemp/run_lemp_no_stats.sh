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
project_sub_folder=${project}/${TSTAMP}_${_project}_PH_LEMP_NO_STAT #_${prefix}
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

APP="25 40 250 500"

#APP+="ep.B"
#Final test set
#APP+="ep.B bt.B lu.B sp.B ua.B cg.B ft.B is.C"
#cpu_number_to_map=(0x1 0x2 0x4 0x8)
#echo "using "cpu_number_to_map" to select the number of CPUs"

for it in `seq $iter`
do
	echo "ITERATION ${it}: " | tee -a ${_project_sub_folder}/time_taken_out
	for app in $APP
	do
		echo "FOR RESPONSE TIME ${app}: " | tee -a ${_project_sub_folder}/time_taken_out | tee -a ${_project_sub_folder}/interm_out
		ssh root@10.4.4.222 "cd /var/www/travel_list/routes; cp php-script-${app}ms.php web.php"

		ab -n 100 -c 10 http://10.4.4.222/ | tee ${_project_sub_folder}/interm_out

		cat ${_project_sub_folder}/interm_out | grep "Time taken for tests" -A 9 | tee -a ${_project_sub_folder}/time_taken_out
		
		sleep 4
	done

done

echo -e "\n\n$0 ALL DONE\n\n"


