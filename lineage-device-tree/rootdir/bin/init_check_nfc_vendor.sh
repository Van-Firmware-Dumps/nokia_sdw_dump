#!/vendor/bin/sh

if [ -c /dev/sec-nfc ]; then
     setprop persist.vendor.nfc.chip.type sec
elif [ -c /dev/tms_nfc ]; then
     setprop persist.vendor.nfc.chip.type tms
else
     setprop persist.vendor.nfc.chip.type nonfc
fi
