#/bin/bash

START=$(date +%s)

DEVICE="$1"
cfg=

case "$DEVICE" in
	clean)
		make clean
		exit
		;;
	mrproper)
		make mrproper
		exit
		;;
	distclean)
		make distclean
		exit
		;;
	captivate)
		cfg=ga3_eur_defconfig
		;;
	noconfig)
		#don't redo config
		;;
#	captivate_no_debug)
#		cfg=ga3_eur_defconfig_no_debug
#		;;
#	galaxysb)
#		cfg=aries_galaxysb_defconfig
#		;;
#	vibrant)
#		cfg=aries_vibrant_defconfig
#		;;
	*)
		echo "Usage: $0 DEVICE"
		echo "Example: ./build.sh galaxys"
		echo "Supported Devices: captivate, galaxys, galaxysb, vibrant"
		exit 2
		;;
esac

# Ensure basic initramfs structure is there
for i in /data /dev /proc /sys /system /voodoo/logs /voodoo/tmp /voodoo/tmp/mnt /voodoo/tmp/sdcard; do
	if [ ! -d ../9010initramfs/full-uncompressed$i ]; then
		mkdir ../9010initramfs/full-uncompressed$i
	fi
done

#export KBUILD_BUILD_VERSION="1.0.0"
if [ -n "$cfg" ]; then
	echo "Using config ${cfg}"

	make ${cfg}  || { echo "Failed to make config"; exit 1; }
fi

echo "Making Kernel Modules..."
make modules -j $(grep 'processor' /proc/cpuinfo | wc -l) || { echo "Failed to make kernel modules"; exit 1; }
echo "done."

echo -n "Copying Kernel Modules to initramfs..."
{
#cp drivers/bluetooth/bthid/bthid.ko ../9010initramfs/full-uncompressed/lib/modules/bthid.ko
cp fs/cifs/cifs.ko ../9010initramfs/full-uncompressed/lib/modules/cifs.ko
#cp drivers/net/wireless/bcm4329/dhd.ko ../9010initramfs/full-uncompressed/lib/modules/dhd.ko
cp fs/ext4/ext4.ko ../9010initramfs/full-uncompressed/lib/modules/ext4.ko
cp fs/jbd2/jbd2.ko ../9010initramfs/full-uncompressed/lib/modules/jbd2.ko
cp drivers/staging/android/logger.ko ../9010initramfs/full-uncompressed/lib/modules/logger.ko
#cp drivers/onedram_svn/modemctl/modemctl.ko ../9010initramfs/full-uncompressed/lib/modules/modemctl.ko
#cp drivers/onedram_svn/onedram/onedram.ko ../9010initramfs/full-uncompressed/lib/modules/onedram.ko
#cp drivers/scsi/scsi_wait_scan.ko ../9010initramfs/full-uncompressed/lib/modules/scsi_wait_scan.ko
#cp drivers/onedram_svn/svnet/svnet.ko ../9010initramfs/full-uncompressed/lib/modules/svnet.ko
#cp drivers/samsung/vibetonz/vibrator.ko ../9010initramfs/full-uncompressed/lib/modules/vibrator.ko
cp drivers/net/tun.ko ../9010initramfs/full-uncompressed/lib/modules/tun.ko

} || { echo "failed to copy kernel modules"; exit 1; }
echo "done."

echo "Making Kernel Image..."
make zImage -j $(grep 'processor' /proc/cpuinfo | wc -l) || { echo "Failed to make kernel image"; exit 1; }
echo "done."

echo -n "copying zImage to flash dir..."
{
rm -f ../skullcapflash/updates/zImage
cp arch/arm/boot/zImage ../skullcapflash/updates/zImage
} || { echo "failed to copy zImage"; exit 1; }
echo " done"

ZIPNAME=skullcap-voodoo-kernel-i897-v$(cat ../kernel/.version)-CWM

echo -n "creating flash zip"
{
#rm -f ../skullcapflash.zip
cd ../skullcapflash/
zip $ZIPNAME -r * 
mv $ZIPNAME.zip ../$ZIPNAME.zip
} || { echo "failed to create zip"; exit 1; }

echo -n "copying zip to the phone..."
{
cd ..
echo "kernel version is $(cat kernel/.version)" 
adb shell mkdir /sdcard/sgs-kernel-flasher >/dev/null
adb push $ZIPNAME.zip /sdcard/sgs-kernel-flasher/$ZIPNAME.zip
} || { echo "failed to copy zip to phone"; }

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n" $E_SEC
