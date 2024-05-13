#!/system/bin/sh

to_hex() {
  echo -en "$1" | xxd -pc 256 | tr -d '[ \n]'
}

hexpatch() {
  local h_from=$(to_hex "$2")
  local rpadding=$(printf '%*s' $((${#2}-${#3})))
  local h_to=$(to_hex "$3$rpadding")

  echo -E "I${#2}: $2" >&2
  echo -E "O${#3}: $3" >&2
  echo I${h_from}: $h_from >&2
  echo O${h_to}: $h_to >&2

  [ ! -f $1 ] && abort 4 "File to be patched, $1, does not exist."
  local output=$($mb hexpatch $1 $h_from $h_to 2>&1)
  count=$((count+1))

  if [ "${output/Patch/}" != "$output" ]; then
    echo $output >&2
    echo Patch $count succeeded. >&2
    return 0
  else
    abort $((128+$count)) "Patch $count failed."
  fi
}

abort() {
  echo "$2" >&2
  exit $1
}

# Detect the active boot slot
active_slot=$(getprop ro.boot.slot_suffix)
if [ -z "$active_slot" ]; then
  echo "No active slot found, assuming non-A/B device." >&2
  recovery="/dev/block/bootdevice/by-name/boot"  # Default recovery path for non-A/B
else
  recovery="/dev/block/bootdevice/by-name/boot$active_slot"
fi

MODDIR=${0%/*}
if [ ${0##*/} = uninstall.sh ]; then
  set -- --reverse
  log=/data/adb/modules/twrp-helper.log
fi

mydir=${MODDIR:-/data/adb/modules/twrp-helper}
log=${log:-$mydir/twrp-helper.log}
if ([ ! -v BOOTMODE ] || [ "$BOOTMODE" = false ]) && [ ! -t 1 ]; then
  exec &> $log
fi

count=0
mb=/data/adb/magisk/magiskboot
store=/storage/emulated/0/Download
rd=ramdisk.cpio

if [ "$1" = --reverse ]; then
  new_twrp=twrp-unpatched.img
else
  new_twrp=twrp-patched.img
fi

if [ -v DEBUG ]; then
  echo "PWD     = $PWD" >&2
  echo "MODDIR  = $MODDIR" >&2
  echo "mydir   = $mydir" >&2
  echo "log     = $log\n" >&2
fi

cd $mydir || echo "Failed to change directory to $mydir. Continuing in $PWD..." >&2
[ ! -b "$recovery" ] && abort 1 "Can't locate recovery block device for slot $active_slot."
trap 'rm -f recovery_dtbo kernel ramdisk.cpio strings twrp.img' EXIT

echo "Reading recovery image from $recovery..." >&2
cat $recovery > $twrp
$mb unpack $twrp
[ ! -f $rd ] && abort 2 'Failed to unpack ramdisk.'

IFS=$'\t\n'
while read -r from; do
