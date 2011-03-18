#/bin/bash

START=$(date +%s)

DEVICE="$1"

case "$DEVICE" in
	clean)
		make clean
		exit
		;;
	captivate)
		cfg=ga3_eur_defconfig
		;;
	noconfig)
		#don't redo config
		;;
#	galaxys)
#		cfg=aries_galaxys_defconfig
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

#export KBUILD_BUILD_VERSION="1.0.0"
echo "Using config ${cfg}"

make ${cfg}  || { echo "Failed to make config"; exit 1; }
make -j $(grep 'processor' /proc/cpuinfo | wc -l) || { echo "Failed to make kernel"; exit 1; }

echo -n "Copying Kernel and Modules to initramfs..."
{
#cp drivers/bluetooth/bthid/bthid.ko ../../src/9010initramfs/full-uncompressed/lib/modules/bthid.ko
cp fs/cifs/cifs.ko ../9010initramfs/full-uncompressed/lib/modules/cifs.ko
#cp drivers/net/wireless/bcm4329/dhd.ko ../../src/9010initramfs/full-uncompressed/lib/modules/dhd.ko
cp fs/ext4/ext4.ko ../9010initramfs/full-uncompressed/lib/modules/ext4.ko
cp fs/jbd2/jbd2.ko ../9010initramfs/full-uncompressed/lib/modules/jbd2.ko
cp drivers/staging/android/logger.ko ../9010initramfs/full-uncompressed/lib/modules/logger.ko
#cp drivers/onedram_svn/modemctl/modemctl.ko ../../src/9010initramfs/full-uncompressed/lib/modules/modemctl.ko
#cp drivers/onedram_svn/onedram/onedram.ko ../../src/9010initramfs/full-uncompressed/lib/modules/onedram.ko
#cp drivers/scsi/scsi_wait_scan.ko ../../src/9010initramfs/full-uncompressed/lib/modules/scsi_wait_scan.ko
#cp drivers/onedram_svn/svnet/svnet.ko ../../src/9010initramfs/full-uncompressed/lib/modules/svnet.ko
#cp drivers/samsung/vibetonz/vibrator.ko ../../src/9010initramfs/full-uncompressed/lib/modules/vibrator.ko
cp drivers/net/tun.ko ../9010initramfs/full-uncompressed/lib/modules/tun.ko

} || { echo "failed to copy kernel and modules"; exit 1; }
echo "done."

echo -n "copying zImage to flash dir..."
{
rm -f ../skullcapflash/updates/zImage
cp arch/arm/boot/zImage ../skullcapflash/updates/zImage
} || { echo "failed to copy zImage"; exit 1; }
echo " done"

echo -n "creating flash zip"
{
rm -f ../skullcapflash.zip
cd ../skullcapflash/
zip -r ../skullcapflash *
} || { echo "failed to create zip"; exit 1; }

echo -n "copying zip to the phone..."
{
cd ..
echo "kernel version is $(cat kernel/.version)" 
adb push skullcapflash.zip /sdcard/sgs-kernel-flasher/skullcapflash.zip
} || { echo "failed to copy zip to phone"; }

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n" $E_SEC
