##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

REPLACE=""

##########################################################################################
# Function Callbacks
##########################################################################################

print_modname() {
  ui_print "*******************************"
  ui_print "          TWRP Helper          "
  ui_print "*******************************"
}

on_install() {
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

  # Detect active boot slot for A/B devices
  active_slot=$(getprop ro.boot.slot_suffix)
  if [ -z "$active_slot" ]; then
    ui_print "No active slot found, assuming non-A/B device."
    active_slot="_a"  # Default to slot A if no suffix found
  fi

  ui_print "Active slot: $active_slot"

  # Construct the boot partition path for the active slot
  BOOT_PARTITION="/dev/block/bootdevice/by-name/boot$active_slot"
  ui_print "Boot partition path: $BOOT_PARTITION"

  if [ ! -e "$BOOT_PARTITION" ]; then
    abort "Boot partition for active slot not found!!"
  fi

  if [ ${MAGISK_VER%%.*} -lt 19 ]; then
    abort 'This module requires Magisk v19 or later.'
  fi
}

set_permissions() {
  post_installation

  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
}

post_installation() {
  ui_print "- Running post-installation"
  
  # Handle dynamic patching based on active slot
  export BOOTMODE
  ( cd $MODPATH; ln -s service.sh uninstall.sh )
  /system/bin/sh $MODPATH/service.sh --slot $active_slot 2>&1
  status=$?

  # Errors < 128 from service.sh are fatal.
  if [ $status -gt 0 ] && [ $status -lt 128 ]; then
    abort "Fatal error $status. Installation aborted."
  fi

  ui_print "Do not be alarmed if patching fails at this stage. This simply"
  ui_print "means that you do not currently have a patchable recovery image."
  ui_print "Perhaps your image is already patched and you are merely upgrading"
  ui_print "this module."
  ui_print "The module is correctly installed and will check your recovery"
  ui_print "partition every time the device boots. Whenever pristine TWRP is"
  ui_print "found, such as would be the case following a TWRP upgrade, for"
  ui_print "example, it will be dynamically patched."
}
