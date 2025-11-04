lcdinit
textout -1 -1 "Debian for WM8505 Netbooks" ffffff
textout -1 -1 "by lrussell887" c0c0c0
textout -1 -1 "" 000000

textout -1 -1 "Loading Kernel..." 808080
fatload mmc 0 0 /script/uzImage.bin
textout -1 -1 "Starting Linux..." 808080
setenv bootargs root=/dev/mmcblk0p2 rw noinitrd console=tty1 rootwait audit=0
bootm 0
