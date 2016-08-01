#!/system/bin/sh
#
# zRam / Compache manager
# TheXfactor2011
# 
#
 
isramzswap="$(find /system/lib/modules/ -name ramzswap.ko 2>/dev/null)"
isramzswapbuiltin="$(ls -l /dev/block/ramzswap0 2>/dev/null)"
 
if [ -n "$isramzswap$isramzswapbuiltin" ] ; then
    MODULE=ramzswap
    DEV=/dev/block/ramzswap0
else
    DEV=/dev/block
    MODULE=zram
    SYSFS_PATH=/sys/devices/virtual/block
fi
 
#Number of CPU cores and bytes of physical memory
num_cpus=$(grep -c processor /proc/cpuinfo)

case "$1" in
   start)

#individual disk size is divided by NUM_CPUS
mem_size=$(($2 * 1024))
zram_size=$(($mem_size / $num_cpus))

if [ $MODULE = zram ]; then
        # Load zram and resize the disks
	echo $num_cpus
        modprobe zram num_devices=$num_cpus
        for i in $SYSFS_PATH/zram*; do
                echo $zram_size > $i/disksize
        done
 
        # Create the swap spaces and start swapping
        for i in $DEV/zram*; do
                mkswap $i > /dev/null
                swapon $i
        done
else
        rzscontrol $DEV --disksize_kb=$2 --init
fi
#drop all caches so memory can be reset with swap
echo 3 > /proc/sys/vm/drop_caches
;;
stop)
if [ $MODULE = zram ]; then
        for i in $DEV/zram*; do
                swapoff $i >/dev/null 2>&1
        done   
else
      swapoff $DEV >/dev/null 2>&1      
fi
rmmod $MODULE >/dev/null 2>&1
   ;;
   stats)
     if [ $MODULE = ramzswap ]; then
         rzscontrol $DEV --stats
     else
for i in $SYSFS_PATH/zram*; do
         cd $i && for k in * ; do
             echo -n "$k:"
             cat $k
         done
done
     fi
   ;;
   *)
      echo "Usage: $0 {start <size>|stop|stats}"
      exit 1
esac
 
exit 0