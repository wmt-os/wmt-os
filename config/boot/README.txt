WMT OS Setup
============

WMT OS needs a few settings before its first boot -- a hostname, timezone,
username, and account passwords. There are two ways to provide them.

On Windows or Windows CE:
  Run run-setup.cmd (double-clicking it usually works). Fill in the form and
  click Save, and it writes setup.ini straight to the card for you.

Otherwise:
  Open wmt-os-setup.html in just about any web browser. Fill in the form and
  click Save to download setup.ini, then copy it to the card's boot partition
  root, next to this file.

Boot the device and WMT OS takes it from there.
