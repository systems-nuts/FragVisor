The FragVisor Aggregate VM Hypervisor


# Guide to run FragVisor

This guide explains how FragVisor can be setup on a 4 nodes cluster. 
Indeed, the same instructions apply for smaller and larger clusters, but we fully tested it on 2, 3, and 4 nodes clusters.
Hardware requirements are listed below.
For the sake of this guide, we consider a 4 nodes cluster, where nodes are called echo0, echo1, echo4, and echo5. We will use nodes in this exact order:
* echo5 (first node)
* echo4
* echo0
* echo1 (last node)

Note that in the case of a 2 and a 3 nodes cluster, the nodes running FragVisor would be in the same given order.
Finally, FragVisor requires a host (origin) node to start the VM, in this case the host node is echo5.


## Note about the directory structure

`~/kh$` - contains the kernel code used to start a VM using FragVisor (Each node has its copy of the kernel code. Any change in the kernel code has to be replicated on all the nodes and the kernel is to be installed manually.)

`~/c$` - contains source code for FragVisor kvmtool and ramdisks. (This can be run only from the host node, however it is being shared with other nodes via NFS)


## Connecting to the nodes console terminals and Restarting the machines


In the case of the echo machines, echo5, echo4, echo0, and echo1, do the following:

	ipmitool -I lanplus -H echo5-ipmi -U $IPMI_USER -P $IPMI_PASSWORD sol activate

Where $IPMI_USER and $IPMI_PASSWORD are yours ipmi user and password. Instead of echo5-ipmi, please use echo4-ipmi, echo1-ipmi, and echo0-ipmi to access the other nodes.

Restarting an echo machines via IPMI:

	ipmitool -I lanplus -H echo5-ipmi -U $IPMI_USER -P $IPMI_PASSWORD  power cycle


## Run FragVisor

### Compile the kernel

Make sure a copy of the kernel source tree exists on every node.

Make sure that `#define CONFIG_POPCORN_ORIGIN_NODE` in `include/linux/popcorn/debug.h` is set only for the origin node (in our case, echo5). All the other nodes must **NOT** define `CONFIG_POPCORN_ORIGIN_NODE`.

Compile and install the kernel on every node with:
	
	make -jN
	sudo make modules_install
	sudo make install

Where N is equal to the number of cores/threads available on the machines, or at maximum double.

### Setup the messaging layer

Several scripts are available for the 2, 3, adn 4 nodes setup:

	echo5:~$ ./msg\_pophype4node\_echo.sh (For a 4 node configuration)
	echo5:~$ ./msg\_pophype3node\_echo.sh (For a 3 node configuration)
	echo5:~$ ./msg\_pophype2node\_echo.sh (For a 2 node configuration)


### Automatic initialize a FragVisor VM 

A FragVisor VM uses the kvmtool (lkvm) as the hypervisor.
We use a script to start the VM using the kvmtool. The script also takes care of the various pre requisites that are to be handled before the VM is initialized.

`echo5:~/c$ ./run.sh 1 1 0` (This is the default configuration we use to run our 4 nodes experiments)

The first argument compiles lkvm, the second one compiles the kernel and the third enables cscope. 


### Manually initialize a FragVisor VM

This is possible with the command:

	sudo bash -c "./lkvm run -a 1 -b 1 -x 1 -y 1 -w 4 -i $USER/c/ramdisk.gz -k $USER/kh/arch/x86/boot/bzImage -m 16384 -c 4 -p \"root=/dev/ram rw fstype=ext4 spectre\_v2=off nopti pti=off numa=fake=4 percpu\_alloc=page\" --network mode=tap,vhost=1,guest\_ip=10.4.4.222,host\_ip=10.4.4.221,guest\_mac=00:11:22:33:44:55"

`-i $USER/c/ramdisk.gz` → This is the ramdisk you want to use. 

`-k $USER/kh/arch/x86/boot/bzImage` → This is the kernel you want to use to boot the VM. (We use a modified host kernel)

`-m 16384` → Memory given to the VM

`-c 4` → Number of vCPUs to be given to the VM

`--network mode=tap` → Using network in tap mode

`guest\_ip=10.4.4.222` → IP assigned to VM

2-nodes case: `-a 1 -b 1 -w 2 ........ numa=fake=2`

3-nodes case: `-a 1 -b 1 -x 1 -w 3 ........ numa=fake=3`

4-nodes case: `-a 1 -b 1 -x 1 -y 1 -w 4 ........ numa=fake=4`


### Bootup process

While booting FragVisor you may start seeing several messages from the userspace applications.
Eventually, prints halts after a while, please keep on pressing any key to continue with the bootup process if this happens.
Once the boot completes you can see a message in green stating “Initstrap done”.


### Connecting to the VM

There exists a bug which requires us to continuously enter some keys to get the output of any entered command. The work-around is to ssh into the VM from a different terminal.

	echo<num>:~:ssh root@10.4.4.222
	
Where 10.4.4.222 is the IP of the VM.

You should be able to enter the VM. If the VM asks for a password you can try the following combinations - (username, password) → (root, root); (root, popcorn), (popcorn, popcorn)


### Verifying the setup

Once in the VM. Go to the home folder and run

	root@(none):~#taskset 0x1 ./ep.B.x.ser.van
	root@(none):~#taskset 0x2 ./ep.B.x.ser.van
	root@(none):~#taskset 0x4 ./ep.B.x.ser.van
	root@(none):~#taskset 0x8 ./ep.B.x.ser.van

Check htop of the VM and all the host nodes to verify activity on the vCPUs and pCPUs respectively.


### Restarting the VM

The code to handle VM restarts is still a work in progress, hence to restart the VM we generally require the hosts to be restarted and the FragVisor VM to be initialized on it again. Make sure to restart the hosts using the IPMI commands as the initialized messaging layer can increase the time of restarts. (Note as we use a ramdisk the VM doesn’t store any information from the previous sessions)



## Making changes to the kernel

### Disable kernel debug messages (printks)
	:~$: vim kh/include/popcorn/debug.h
Set the PERF\_EXP to 1. (Always do this while collecting numbers.)

### Disable extra sanity checks
	:~/kh$: make menuconfig

	Popcorn Distributed Execution Support 
	
	[ ]   Log debug messages for Popcorn
	[ ]   Perform extra-sanity checks
	[ ]   Collect performance statistics
Make sure all of these are unselected.

### To recompile and install the new kernel:
To recompile and install the modified kernel you can use the following script
	
	~/kh$: ./build.sh 1
