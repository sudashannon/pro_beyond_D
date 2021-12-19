"bin\sunxi-fel.exe" -p uboot u-boot-sunxi-with-spl.bin.V3s write 0x41000000 zImage write 0x41800000 sun8i-v3s-licheepi-zero-dock.dtb.PF6 write 0x41900000 boot_fel_initrd.scr write 0x41A00000 rootfs.cpio.gz.uImage

@echo "download complete! now run linux ..."
@sleep 5