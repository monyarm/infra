#!/bin/bash
# Exit immediately on error and treat unset variables as an error.
set -eu

# --- DVD and Game Disc Ripping Utility ---

# --- Configuration ---
DEVICE="/dev/sr0"

# --- Main Logic Functions ---
get_disc_info() {
  echo "--- Gathering disc information from $DEVICE ---"
  local isoinfo_output
  isoinfo_output=$(isoinfo -d -i "$DEVICE")

  BS=$(echo "$isoinfo_output" | grep -oP '^Logical block size is: \K\d+' || echo "2048")

  # The 'count=' prefix is intentionally part of the VS variable for dd's syntax.
  local vs_val
  vs_val=$(echo "$isoinfo_output" | grep -oP '^Volume size is: \K\d+' || echo "")
  if [[ -n $vs_val ]]; then
    VS="count=$vs_val"
  else
    VS=""
  fi

  VSID=$(echo "$isoinfo_output" | grep -oP 'Volume set id: \K\S+' || echo "")
  VID=$(echo "$isoinfo_output" | grep -oP '^Volume id: \K\S+' | tr -dc '[:alnum:]-_.!?"' || echo "")
}

determine_disc_type() {
  echo "--- Determining disc type ---"
  if ! lsdvd "$DEVICE" &>/dev/null; then
    GAME="1"
    VS="" # Volume size is not reliable for non-DVD-Video discs.
    echo "Disc appears to be a game or data disc."
  else
    GAME="0"
    echo "Disc appears to be a DVD-Video. Spinning up disc..."
    timeout 5 cvlc -I dummy "dvd://$DEVICE" --sout-all vlc://quit &>/dev/null || true
  fi
}

determine_output_filename() {
  echo "--- Determining output filename ---"
  if [[ -n ${1-} ]]; then
    OF="${1%.iso}"
  elif [[ -n $VID && $VID != "NOT_SET" && $VID != "UNDEFINED" && $VID != "$VSID" ]]; then
    OF="${VID}_${VSID}"
  elif [[ -n $VID && $VID != "NOT_SET" && $VID != "UNDEFINED" ]]; then
    OF="$VID"
  else
    echo "Could not determine a good filename from disc metadata. Generating from hash..."
    OF=$(dd if="$DEVICE" bs=2048 count=32 2>/dev/null | md5sum | cut -d' ' -f1)
  fi
  echo "Output file will be: $OF.iso"
}

rip_disc() {
  echo "--- Starting rip process ---"
  if [[ $GAME -eq 1 ]]; then
    echo "Using 'pv | dd' for a direct data rip..."
    pv -tpreb "$DEVICE" | dd of="$OF.iso" bs="$BS" "$VS"
  else
    echo "Using 'ddrescue' for a robust DVD-Video rip..."
    eject -x48 "$DEVICE"
    ddrescue -n -a 10M -b "$((BS * 4))" -c 2048 "$DEVICE" "$OF.iso" "$OF.map"
    ddrescue -d -b "$((BS * 4))" -c 2048 "$DEVICE" "$OF.iso" "$OF.map"
    rm -f "$OF.map" "$OF.map.bak" &>/dev/null
  fi
  echo "Rip process complete."
}

post_rip_tasks() {
  echo "--- Performing post-rip tasks (async) ---"
  echo "Calculating checksums in the background..."
  md5sum "$OF.iso" &
  sha1sum "$OF.iso" &

  # Wait a moment before ejecting to allow other processes to start.
  sleep 3
  echo "Ejecting disc in the background..."
  eject -m "$DEVICE" &

  sync

  echo "Dropping system caches..."
  sudo /usr/bin/drop_caches
}

# --- Main Script ---
get_disc_info
determine_disc_type "$@"
determine_output_filename "$@"
rip_disc
post_rip_tasks

echo "--- All tasks initiated. Checksum and eject are running in the background. ---"
