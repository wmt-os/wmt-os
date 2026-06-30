setenv LOAD_MSG Loading Kernel Image...
setenv BOOT_MSG Starting Linux...

lcdinit

textout 20 20 "${KERNEL_RELEASE}" 606060
textout 20 50 "${BUILD_TIME}" 606060

textout 316 200 "*** WMT OS ***" 3d85c6
textout 298 230 "Powered by Debian" c0c0c0

textout 304 290 "by Logan Russell" 808080

textout 20 440 "${LOAD_MSG}" c0c0c0
fatload mmc 0 0 /script/uzImage.bin

textout 20 410 "${LOAD_MSG}" c0c0c0
textout 20 440 "${BOOT_MSG}" 00ff00
setenv bootargs root=/dev/mmcblk0p2 rw noinitrd console=tty1 rootwait
bootm 0
