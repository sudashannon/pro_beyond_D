# Uboot

## 构成

uboot分为uboot-spl和uboot两个组成部分。SPL是Secondary Program Loader的简称，即第二阶段程序加载器，这里所谓的第二阶段是相对于SOC中的BROM来说的，可以参考 [bootflow](./Bootflow.md) 一文中的介绍。事实上，SOC启动后最先执行的是BROM中的固化程序，并由此程序决定后续运行哪里的启动程序。当外部ram没有就绪的时候，程序只能利用SOC内部的ram进行执行，此时由于不同SOC的ram不尽相同，且部分SOC可能只有很小的ram，因此uboot独立出了SPL用于解决这样的问题。SPL只需要很少的ram即可运行，并且会初始化好外部ram以供后续阶段的bootloader或者kernel运行。

## 编译

编译的具体内容这里不再赘述，可以参考[prepare](./prepare.md) 一文。

需要注意的是，uboot编译是否产生SPL是由用户自行配置决定的，在本项目中，具体配置如下：

```
CONFIG_ARM=y
CONFIG_ARCH_SUNXI=y
# CONFIG_ARMV7_NONSEC is not set
CONFIG_MACH_SUN8I_V3S=y
CONFIG_DRAM_CLK=360
CONFIG_DRAM_ZQ=14779
CONFIG_DEFAULT_DEVICE_TREE="sun8i-v3s-licheepi-zero"
# CONFIG_CONSOLE_MUX is not set
CONFIG_SPL=y
# CONFIG_CMD_IMLS is not set
# CONFIG_CMD_FLASH is not set
# CONFIG_CMD_FPGA is not set
# CONFIG_NETDEVICES is not set
CONFIG_OF_LIBFDT_OVERLAY=y
```

## 启动

在[bootflow](./Bootflow.md) 一文中，我们简单介绍了v3s bootrom的行为，
