##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
REPLACE=""

##########################################################################################
# Function Callbacks
##########################################################################################

# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.

##########################################################################################
# Installation messages
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
  if [ -n "$(getprop ro.boot.slot_suffix)" ]; then
    active_slot=$(getprop ro.boot.slot_suffix)
  else
    active_slot="_a"  # Default to slot A if no suffix found
  fi

  ui_print "Active slot: $active_slot"

  # Ensure the script handles A/B partitioning
  BOOT_PARTITION="/dev/block/bootdevice/by-name/boot$active_slot"

  if [ ! -f "$BOOT_PARTITION" ]; then
    abort "Boot partition for active slot not found!"
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
