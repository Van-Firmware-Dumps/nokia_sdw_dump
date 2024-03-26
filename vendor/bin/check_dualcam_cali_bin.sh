#! /bin/bash

Log(){
    log -p d -t check_dualcam_cali_bin $1
    echo $1
}

# 有问题的设备中，dualcam_cali.bin文件缺失或者内容不正确；
# 这里检查 hw_sku + board_id：
# 如果是有问题的设备，设置属性值触发 bin 文件通过 rc 被 copy 到指定位置。
# Copy 只做一次，所以需要 persist 属性标记 copy 已经完成。

# 检查 persist.vendor.ontim.dualcam_cali.bin_copied，如果 true，返回；
if [ "$(getprop persist.vendor.ontim.dualcam_cali.bin_copied)" = "true" ]
then
    Log "Already done: dualcam_cali.bin had been copied."
    exit
fi

# 检查 board id；
# 如果是空的 board_id，返回。
cur_board_id=`getprop ro.vendor.boardid`
if [ -z "${cur_board_id}" ]
then
    Log "Ignore empty board_id."
    exit
fi

# board_id 为 0004 及以上(即 PVT 以上)的所有 hw sku 都不需要更新 bin.
if [ "${cur_board_id}" -ge "0004" ]
then
    Log "Ignore dualcam_cali bin replacing for board_id[${cur_board_id}]"
    exit
fi

cur_hw_sku=`getprop ro.vendor.hw_sku`
# 检查 hw_sku + board id；
# 如果是空的 hw_sku，返回。
if [ -z "${cur_hw_sku}" ]
then
    Log "Ignore empty hw_sku."
    exit
fi
# 如果是不期望 replace 的 hw_sku + board_id，返回。
Log "ro.vendor.boardid[${cur_board_id}], ro.vendor.hw_sku[${cur_hw_sku}]"
# board_id 为 0003 且hw_sku为 0001 (TMO)的组合不需要 replace.
if [ "${cur_board_id}" -eq "0003" && "${cur_hw_sku}" -eq "0001" ]
then
    Log "Ignore dualcam_cali bin replacing for board_id[${cur_board_id}]hw_sku[${cur_hw_sku}]"
    exit
fi

# 获取Camera景深 一 二供信息：
# 获取路径：/data/vendor/cameraserver/hwinfo 下 cam_depth_lens_mfr
cam_depth_lens_mfr=`/vendor/bin/cat /data/vendor/cameraserver/hwinfo/cam_depth_lens_mfr | /vendor/bin/cut -d '=' -f 2`
if [ -z "${cam_depth_lens_mfr}" ]
then
    Log "Ignore empty cam_depth_lens_mfr!"
    exit
fi
Log ".../hwinfo/cam_depth_lens_mfr: ${cam_depth_lens_mfr}"
# 景深
# 一供：cam_depth_lens_mfr=2_SHD1_gc02m1b_union，对应 golden_2_SHD1_gc02m1b_union.bin
# 二供：cam_depth_lens_mfr=2_SHD2_gc02m1b_lce, 对应 golden_2_SHD2_gc02m1b_lce.bin
src_golden_bin=/odm/bin/golden_${cam_depth_lens_mfr}.bin
if [ -f "$src_golden_bin" ]; then
    Log "Camera Golden bin $src_golden_bin exists."
else
    Log "Camera Golden bin [$src_golden_bin] does NOT exist!"
    exit
fi

# 对于符合条件的hw_sku + board_id，更新 "/mnt/vendor/persist/camera/dualcam_cali.bin"
Log "Update /mnt/vendor/persist/camera/dualcam_cali.bin from ${src_golden_bin}"
#cp /odm/bin/dualcam_cali.bin /mnt/vendor/persist/camera/dualcam_cali.bin
cp ${src_golden_bin} /mnt/vendor/persist/camera/dualcam_cali.bin
chown -h root.camera /mnt/vendor/persist/camera/dualcam_cali.bin
chmod 0776 /mnt/vendor/persist/camera/dualcam_cali.bin
# 更新完成后，设置 property 触发 restorecon。
Log "Set property to restorecon for dualcam_cali.bin"
setprop vendor.ontim.check.dualcam_cali bin_updated

