@echo off
:loop
echo 请选择需要烧写的文件
echo 1：烧写uboot       
echo 2：烧写设备树       
echo 3：烧写内核         
echo 4：烧写 squashFS   
echo 5：烧写 jaffs       
echo 6：烧写 全部       
:input
set /p first="请选择："

if %first% == 1 (
echo 烧写uboot......
start sunxi-fel.exe -p spiflash-write 0x000000 my_spi_file\uboot_overlayfs.bin
goto input
)else if %first% == 2 (
echo 烧写设备树......
start sunxi-fel.exe -p spiflash-write 0x100000 my_spi_file\sun8i-v3s-licheepi-zero-dock.dtb
goto input
)else if %first% == 3 (
echo 烧写内核......
start sunxi-fel.exe -p spiflash-write 0x110000 my_spi_file\zImage
goto input
)else if %first% == 4 (
echo 烧写squashFS......
start sunxi-fel.exe -p spiflash-write 0x510000 my_spi_file\rootfs.squashfs
goto input
)else if %first% == 5 (
echo 烧写jaffs.img......
echo 未设置       ......
::start sunxi-fel.exe -p spiflash-write 0x000000 my_spi_file\jffs2.img
goto input
)else if %first% == 6 (
echo 烧写全部......
start sunxi-fel.exe -p spiflash-write 0x000000 my_spi_file\flashimg.bin
goto input
)else if %first% == ? (
goto loop
)

pause