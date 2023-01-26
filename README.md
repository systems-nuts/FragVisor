﻿The FragVisor Aggregate VM Hypervisor

**Guide to run FragVisor**

The following guide explains how FragVisor can be initialized on 4 nodes. The same can be extended to 2 and 3 nodes as well. For the sake of simplicity, we can consider the four nodes that are being used to start the FragVisor VM are echo5, echo4, echo0, and echo1. (In the case of 2 and 3 nodes, the nodes running FragVisor would be in the same given order.)

FragVisor requires a host node to start the VM, in this case the host node is echo5.

**Information about directories:**

`~/kh$` - contains the kernel code used to start a VM using FragVisor (Each node has its copy of the kernel code. Any change in the kernel code has to be replicated on all the nodes and the kernel is to be installed manually.)

`~/c$` - contains source code for FragVisor kvmtool and ramdisks. (This can be run only from the host node, however it is being shared with other nodes via NFS)

**Connecting to the echo machines console terminals and Restarting the machines:**


In the case of echo machines, we use echo5, echo4, echo0, and echo1.

`ipmitool -I lanplus -H echo5-ipmi -U ssrg -P rtlabuser1% sol activate`

Restarting the echo machines via IPMI:

`ipmitool -I lanplus -H echo<num>-ipmi -U ssrg -P rtlabuser1%  power cycle`



**Run FragVisor**

1. **Setup the messaging layer:**
`echo5:~$ ./msg\_pophype4node\_echo.sh (For a 4 node configuration)`

`echo5:~$ ./msg\_pophype3node\_echo.sh (For a 3 node configuration)`

`echo5:~$ ./msg\_pophype2node\_echo.sh (For a 2 node configuration)`

1. **In the FragVisor kvmtool folder:**

To initialize a FragVisor VM we use the kvmtool (lkvm). 
We use a script to start the VM using the tool. The script also takes care of the various pre requisites that are to be handled before the VM is initialized.
**echo5:~/c$ ./run.sh 1 1 0** (This is the default configuration we use to run our 4experiments)

The first argument compiles lkvm, the second one compiles the kernel and the third enables cscope. 

1. **The command to initialize the VM in run.c:** 

`sudo bash -c "./lkvm run -a 1 -b 1 -x 1 -y 1 -w 4 -i $USER/c/ramdisk.gz -k $USER/kh/arch/x86/boot/bzImage -m 16384 -c 4 -p \"root=/dev/ram rw fstype=ext4 spectre\_v2=off nopti pti=off numa=fake=4 percpu\_alloc=page\" --network mode=tap,vhost=1,guest\_ip=10.4.4.222,host\_ip=10.4.4.221,guest\_mac=00:11:22:33:44:55"`

**-i** $USER/c/ramdisk.gz → This is the ramdisk you want to use. 

**-k** $USER/kh/arch/x86/boot/bzImage → This is the kernel you want to use to boot the VM. (We use a modified host kernel)

**-m** 16384 → Memory given to the VM

**-c** 4 ---> Number of vCPUs to be given to the VM

**--network mode=tap** → Using network in tap mode

**guest\_ip**=10.4.4.222 → IP assigned to VM

2node case: -a 1 -b 1 -w 2 ........ numa=fake=2

3-node case: -a 1 -b 1 -x 1 -w 3 ........ numa=fake=3

4-node case: -a 1 -b 1 -x 1 -y 1 -w 4 ........ numa=fake=4

1. **While booting:**
   While booting FragVisor once you start seeing messages from the userspace, you may see that the prints halts after a while, please keep on pressing any key to continue with the bootup process. 
   Once the boot completes you can see a message in green stating “Initstrap done”.

1. **Connecting to the VM:**

There exists a bug which requires us to continuously enter some keys to get the output of any entered command. To walk around it we generally ssh into the VM from a different terminal.

`echo<num>:~:ssh root@10.4.4.222`

You should be able to enter the VM. If the VM asks for a password you can try the following combinations - (username, password) → (root, root); (root, popcorn), (popcorn, popcorn)

**Verifying:**

Once in the VM. Go to the home folder and run,

`root@(none):~#taskset 0x1 ./ep.B.x.ser.van`

`root@(none):~#taskset 0x2 ./ep.B.x.ser.van`

`root@(none):~#taskset 0x4 ./ep.B.x.ser.van`

`root@(none):~#taskset 0x8 ./ep.B.x.ser.van`


Check htop of the VM and all the host nodes to verify activity on the vCPUs and pCPUs respectively.

**Restarting the VM:**

The code to handle VM restarts is still a work in progress, hence to restart the VM we generally require the hosts to be restarted and the FragVisor VM to be initialized on it again. Make sure to restart the hosts using the IPMI commands as the initialized messaging layer can increase the time of restarts. (Note as we use a ramdisk the VM doesn’t store any information from the previous sessions)

**Making changes to the kernel**

1. **Disable kernel debug messages (printks):**
`:~$: vim kh/include/popcorn/debug.h`
Set the PERF\_EXP to 1. (Always do this while collecting numbers.)

1. **Disable extra sanity checks:**

`:~/kh$: make menuconfig`

Popcorn Distributed Execution Support 

```
[ ]   Log debug messages for Popcorn
[ ]   Perform extra-sanity checks
[ ]   Collect performance statistics
```
Make sure all of these are unselected.

1. **To recompile and install the new kernel:**
   To recompile and install the modified kernel you can use the following script,
   `:~/kh$: ./build.sh 1`



