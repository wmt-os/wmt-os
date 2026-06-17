WMT OS
======

FIRST-TIME SETUP

WMT OS needs a hostname, timezone, username, and account passwords before its
first boot.

  Windows or Windows CE:  run setup.cmd, fill in the form, and click Save -- it
  writes setup.ini to the card for you.

  Other systems:  open wmt-os-setup.html in any web browser, fill in the form,
  and click Save, then copy the downloaded setup.ini next to this file.

Boot the device and WMT OS takes it from there.

ROLL BACK A KERNEL

If a kernel update ever misbehaves, you can boot the previous kernel again. Put
the card in a Windows or Windows CE machine and run rollback.cmd -- it shows the
current and previous kernels and switches between them. Reboot to apply; run it
again to switch back.
