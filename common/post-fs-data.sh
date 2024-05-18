#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# Detect active boot slot for A/B devices
active_slot=$(getprop ro.boot.slot_suffix)
if [ -z "$active_slot" ]; then
  active_slot="_a"  # Default to slot A if no suffix found
fi

# Log the active slot for debugging purposes
echo "Active slot: $active_slot" >> $MODDIR/post-fs-data.log

# Example of performing actions based on the active slot
# Add your specific actions here

# Example: Update boot partition path for the active slot
BOOT_PARTITION="/dev/block/bootdevice/by-name/boot$active_slot"
echo "Boot partition path: $BOOT_PARTITION" >> $MODDIR/post-fs-data.log

# Ensure the boot partition exists
if [ ! -e "$BOOT_PARTITION" ]; then
  echo "Boot partition for active slot not found!" >> $MODDIR/post-fs-data.log
  exit 1
fi

# Set system property dynamically using resetprop
resetprop ro.boot.slot_suffix $active_slot

# Additional actions can be performed here based on the detected active slot

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
