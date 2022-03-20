# Prepare

准备工作：

安装gcc，g++

编译工具链下载：

[hard_float_toolchain](https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/)

（除了linaro之外，还有很多其他的工具链，大家有兴趣可以自行尝试）

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

### 启动参数传递和参数配置

在uboot环境变量里面需要设置内核和设备树的加载地址，使用 `boot.scr`可以直接传递这些参数。

* `boot.scr`是由 `boot.cmd`使用 `mkimage`工具生成的。
* `boot.scr`放在TF卡第一分区。

首先安装uboot相关工具（或者使用uboot的repo下tools目录里的）：

> sudo apt install u-boot-tools

然后给对应的platform建立boot.cmd。

### 遇到的问题

1. cc: not found

> 安装gcc

2. ./tools/binman/binman: not found

> 安装python2

### 测试

通过sunxi_fel或者xfel烧录固件到spiflash，观察能否引导SD卡中的image。

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

uboot固件：

linux镜像：

linux设备树：

rootfs镜像：

### 启动方式

V3S的启动流程如下图所示：

![avatar](./docs/pics/Snipaste_2021-12-30_18-02-07.png)

由上图可见，上电后，bootrom将先从SD0口检测有无启动信息，其次才是尝试从SPI0口NOR flash启动，最后是尝试从SPI0的Nand flash启动。

### 烧录方式

#### 从SPI 启动

#### 从SD卡启动
