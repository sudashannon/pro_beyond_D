# Newbie Guide

准备工作：

安装gcc，g++

编译工具链下载：

[hard_float_toolchain](https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/)

（除了linaro之外，还有很多其他的工具链，大家有兴趣可以自行尝试）

启动介质选择：

SD卡或者SPI FLASH都可以，根据自己的板子做决定

## uboot

### 编译流程

1. clone licheepi的uboot repo，使用下面的指令：

> git clone [https://github.com/Lichee-Pi/u-boot.git](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2FLichee-Pi%2Fu-boot.git) -b v3s-current

2. 然后进入目录使用下面指令来编译uboot。

> #默认配置
>
> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-  LicheePi_Zero_defconfig
>
> #进入配置菜单，如果没有额外需求可以不使用该命令
>
> make  ARCH=arm  menuconfig
>
> #编译固件
>
> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-  -j12

3. 如果没有意外，应当此时可以生成所有固件。

注：

如果使用flash作为v3s的启动介质，需要使用v3s-spi-experimental分支的u-boot，并且在menuconfig中配置匹配board的flash：进入到 **Device Drivers ‣ SPI Flash Support，并在option list中选择合适的flash。**

如果使用的是16MB以上的flash，需要勾选flash bank支持选项，否则最多只能读到16MB：对应宏**CONFIG_SPI_FLASH_BAR。**

### 启动参数传递和参数配置

#### 文件传递

在uboot环境变量里面需要设置内核和设备树的加载地址，使用 `boot.scr`可以直接传递这些参数。

* `boot.scr`是由 `boot.cmd`使用 `mkimage`工具生成的。
* `boot.scr`放在TF卡第一分区。

首先安装uboot相关工具（或者使用uboot的repo下tools目录里的）：

> sudo apt install u-boot-tools

然后给对应的platform建立boot.cmd。

最后生成boot.src文件。

```
 mkimage -C none -A arm -T script -d bootBSP.cmd boot.scr
```

#### 编译时指定

在文件include/configs/sun8i.h中添加默认bootcmd和bootargs的环境变量设置，注意添加的位置在“#include <configs/sunxi-common.h>”的前边。

```
#define CONFIG_BOOTCOMMAND   "sf probe 0; "                           \
                             "sf read 0x41800000 0x100000 0x10000; "  \
                             "sf read 0x41000000 0x110000 0x400000; " \
                             "bootz 0x41000000 - 0x41800000"

#define CONFIG_BOOTARGS      "console=ttyS0,115200 earlyprintk panic=5 rootwait " \
                             "mtdparts=spi32766.0:1M(uboot)ro,64k(dtb)ro,4M(kernel)ro,-(rootfs) root=31:03 rw rootfstype=jffs2"
```

环境命令解析：

* sf probe 0; //初始化Flash设备
* sf read 0x41800000 0x100000 0x10000; //从flash0x100000（1MB）位置读取dtb放到内存0x41800000偏移处。
* sf read 0x41000000 0x110000 0x400000; //从flash0x110000（1MB+64KB）位置读取dtb放到内存0x41000000偏移处。
* bootz 0x41000000 （内核地址）- 0x41800000（dtb地址） 启动内核

启动参数解析：

* console=ttyS0,115200 earlyprintk panic=5 rootwait //在串口0上输出信息
* mtdparts=spi32766.0:1M(uboot)ro,64k(dtb)ro,4M(kernel)ro,-(rootfs) //spi32766.0时设备名，后面是分区大小、名字、读写属性。
* root=31:03 rw rootfstype=jffs2 //通过root=31:03来告诉内核rootfs的位置mtdblock3；根文件系统格式为jffs2。

### 遇到的问题

1. cc: not found

   > 安装gcc
   >
2. ./tools/binman/binman: not found

   > 安装python2
   >
3. uboot启动报错：SF: unrecognized JEDEC id bytes: 0b, 40, 18
   由于开发板的FLASH没在支持列表（`xt25f128b`），所以需要自己添加。修改 `u-boot/drivers/mtd/spi/spi_flash_ids.c`，根据上面flash信息增加 `xt25f128b`：

   ```
   const struct spi_flash_info spi_flash_ids[] = {
       ...
   	{"w25q128fw",	   INFO(0xef6018, 0x0,	64 * 1024,   256, RD_FULL | WR_QPP | SECT_4K) },
   	{"xt25f128b",	   INFO(0x0b4018, 0x0,	64 * 1024,   256, RD_FULL | WR_QPP | SECT_4K) },
       ...
   };
   ```

### 测试

通过sunxi_fel或者xfel烧录固件到spiflash，或者dd烧录到sd卡对应分区后，观察启动log。

![avatar](docs\pics\Snipaste_2022-04-23_15-34-14.png)

## kernel

1. 获取内核源码

> git clone https://github.com/Lichee-Pi/linux.git -b zero-5.2y

2. 初次编译不配置kernel，使用默认配置

> make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm licheepi_zero_defconfig

3. 编译

> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
>
> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
>
> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=out modules
>
> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=out modules_install

编译完成后，zImage在arch/arm/boot/下，驱动模块在out/下。

注：

如果使用SPI FLASH作为启动介质，则需要完成如下修改：


### 遇到的问题

1. fatal error: openssl/bio.h: No such file or directory

> 需要安装libssl-dev

## rootfs

### 介绍

根文件系统首先是内核启动时所mount的第一个文件系统，内核代码映像文件保存在根文件系统中，而系统引导启动程序会在根文件系统挂载之后从中把一些基本的初始化脚本和服务等加载到内存中去运行。

根文件系统包含系统启动时所必须的目录和关键性的文件，以及使其他文件系统得以挂载（mount）所必要的文件。例如：

* init进程的应用程序必须运行在根文件系统上；
* 根文件系统提供了根目录“/”；
* linux挂载分区时所依赖的信息存放于根文件系统/etc/fstab这个文件中；
* shell命令程序必须运行在根文件系统上，譬如ls、cd等命令；

总之：一套linux体系，只有内核本身是不能工作的，必须要rootfs（上的etc目录下的配置文件、/bin /sbin等目录下的shell命令，还有/lib目录下的库文件等···）相配合才能工作。

buildroot可用于构建小型的linux根文件系统，大小最小可低至2M，与内核一起可以放入最小8M的spi flash中。

buildroot中可以方便地加入第三方软件包（其实已经内置了很多），省去了手工交叉编译的烦恼。

* 获取buildroot源码

> wget https://buildroot.org/downloads/buildroot-2021.11.tar.gz

### 配置

make menuconfig

#### 配置 Target optionsTarget options 

```
  -> Target Architecture = ARM (little endian)  
  -> Target Binary Format = ELF 
  -> Target Architecture Variant = cortex-A7 
  -> Target ABI = EABIhf 
  -> Floating point strategy = NEON/VFPv4 
  -> ARM instruction set = ARM
```

#### 配置 Toolchain

此配置项用于配置交叉编译工具链，设置为我们自己所使用的交叉编译器，必须是绝对路径。

目前，在ARM Linux的开发中，人们趋向于使用Linaro( )工具链团队维护的ARM工具链，它以每月一次的 形式发布新的版本，编译好的可执行文件可从网址 downloads/ 下载。Linaro是ARM Linux领域中最著名最具技术成就的开源组织，其会员包括ARM、Broadcom、Samsung、TI、Qualcomm等，国内的海思、中兴、全志和中国台湾的MediaTek 也是它的会员。

一个典型的ARM Linux工具链包含arm-linux-gnueabihf-gcc(后续工具省略前缀)、strip、gcc、objdump、ld、gprof、nm、readelf、 addr2line等。前缀中的“hf”显 示该工具链是完全的硬浮点。

```
Toolchain 
  -> Toolchain type = External toolchain 
  -> Toolchain = Custom toolchain //用户自己的交叉编译器 
  -> Toolchain origin = Pre-installed toolchain //预装的编译器 
  -> Toolchain path =   //编译器绝对路径  
  -> Toolchain prefix = $(ARCH)-linux-gnueabihf //前缀 
  -> External toolchain gcc version = 4.9.x 
  -> External toolchain kernel headers series = 4.1.x 
  -> External toolchain C library = glibc/eglibc  
  -> [*] Toolchain has SSP support? (NEW) //选中 
  -> [*] Toolchain has RPC support? (NEW) //选中 
  -> [*] Toolchain has C++ support? //选中 
  -> [*] Enable MMU support (NEW) //选中
```

如果我们在 buildroot 中的 toolchain 指定外部编译工具为之前在 Ubuntu 上面 apt-get 的交叉编译器，那么编译的时候则会出现错误信息：

> Distribution toolchains are unsuitable for use by Buildroot,
> as they were configured in a way that makes them non-relocatable,
> and contain a lot of pre-built libraries that would conflict with
> the ones Buildroot wants to build.

这是因为 Ubuntu 得到的交叉编译器被配置成不可重定位的，而且包含了一些与 buildroot 相冲突的库，官方解释：

> Distro toolchains, i.ie. toolchains coing with distributions, will
> almost invariably be unsuitable for use with Buildroot:
>
> * they are mostly non-relocatable;
>   * their sysroot is tainted with a lot of extra libraries.
>
> Especially, the toolchains coming with Ubuntu (really, all the Debian
> familly of distros) are configured with –sysroot=/ which makes them
> non-relocatable, and they already contain quite some libraries that
> conflict (in any combination of version, API or ABI) with what Buildroot
> wants to build (i.e. extra libraries, some not even present in
> Buildroot…) but also their mere preence when Buildroot does not expect
> them to be already built (so that a package would enable features when
> it should not).

**所以我们要自己下载交叉编译工具或者让 buildroot 自动下载。**

#### 配置 System configuration

用于设置一些系统配置，比如开发板名字、欢迎语、用户名、密码等。

```
System configuration 
 -> System hostname = Jasonangel //平台名字，自行设置 
 -> System banner = Welcome to xxxxx //欢迎语 
 -> Init system = BusyBox //使用 busybox 
 -> /dev management = Dynamic using devtmpfs + mdev //使用 mdev 
 -> [*] Enable root login with password (NEW) //使能登录密码 
  -> Root password = 123456 //登录密码为 123456
```

#### 配置 Filesystem images

此选项配置我们最终制作的根文件系统为什么格式的，配置如下：

```
-> Filesystem images 
 -> [*] ext2/3/4 root filesystem //如果是 EMMC 或 SD 卡的话就用 ext3/ext4 
  -> ext2/3/4 variant = ext4 //选择 ext4 格式 
 -> [*] ubi image containing an ubifs root filesystem //如果使用 NAND 的话就用 ubifs
```

#### 禁止编译 Linux 内核和 uboot

buildroot 不仅仅能构建根文件系统，也可以编译 linux 内核和 uboot。当配置 buildroot，使能 linux 内核和 uboot 以后 buildroot 就会自动下载最新的 linux 内核和 uboot 源码并编译。但是我们一般都不会使用 buildroot 下载的 linux 内核和 uboot，因为 buildroot 下载的 linux 和 uboot官方源码，里面会缺少很多驱动文件，而且最新的 linux 内核和 uboot 会对编译器版本号有要求，可能导致编译失败。因此我们需要配置 buildroot，关闭 linux 内核和 uboot 的编译，只使用buildroot 来构建根文件系统，首先是禁止 Linux 内核的编译，配置如下：

```
-> Kernel  
 -> [ ] Linux Kernel //不要选择编译 Linux Kernel 选项！
```

接着禁止编译 Uboot，配置如下：

```
-> Bootloaders  
-> [ ] U-Boot //不要选择编译 U-Boot 选项！
```

#### 配置 Target packages

此选项用于配置要选择的第三方库或软件、比如 alsa-utils、ffmpeg、iperf、ftp、ssh等工具，可以按需选择。

配置完成以后就可以编译 buildroot 了，编译完成以后 buildroot 就会生成编译出来的根文件系统压缩包，我们可以直接使用。输入如下命令开始编译：

```
sudo make //注意，一定要加 sudo，而且不能通过-jx 来指定多核编译！！！
```

buildroot 编译过程会很耗时，请耐心等待!编译完成以后就会在 /output/images 下生成根文件系统，即可使用。

编译过程需要一定的额外内存，注意需要留好内存，否则会报错如下：

```
g++: internal compiler error: Killed (program cc1plus) 
Please submit a full bug report
```

### 编译

make即可。

## 烧录和启动

到达本步骤后，此时已编译好的固件如下：

包含SPL的uboot固件：

linux镜像：

linux设备树：

rootfs镜像：

### 分区规划

#### SPI FLASH分区规划

| 分区序号 | 分区大小 | 分区作用   | 地址空间及分区名               |
| -------- | -------- | ---------- | ------------------------------ |
| mtd0     | 1MB      | spl+uboot  | 0x0000000-0x0100000 : "uboot"  |
| mtd1     | 64KB     | dtb文件    | 0x0100000-0x0110000: "dtb"     |
| mtd2     | 4MB      | linux内核  | 0x0110000-0x0510000 : "kernel" |
| mtd3     | 剩余     | 根文件系统 | 0x0510000-0x2000000 : "rootfs" |

注：每个分区的大小必须是所用flash的擦除块大小的整数倍。

#### SD CARD分区规划


### 固件打包

#### SPI FLASH固件打包


#### SD卡固件打包


### 启动方式

V3S的启动流程如下图所示：

![avatar](./docs/pics/Snipaste_2021-12-30_18-02-07.png)

由上图可见，上电后，bootrom将先从SD0口检测有无启动信息，其次才是尝试从SPI0口NOR flash启动，最后是尝试从SPI0的Nand flash启动。

### 烧录方式

目前有两个工具可以进行SPI内的固件烧录，分别是sunxi-fel和xfel。

#### SPI FLASH固件烧录

根据[bootflow](./Bootflow.md) 一文中的分析，v3s的bootrom会引导地址位于0x0处的SPL固件，因此直接将打包好的flash固件直接烧录到0x0地址处即可。

#### SD卡固件烧录

无需烧录，打包时包含了烧写过程。
