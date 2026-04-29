# DDC/CI monitor brightness/contrast control (requires ddcutil)
_ddc_buses() {
  if [ -z "$_DDC_BUSES" ]; then
    local tmpdir
    tmpdir=$(mktemp -d)
    for bus_path in /sys/class/i2c-dev/i2c-*; do
      local busnum=${bus_path##*/i2c-}
      (timeout 1.5 ddcutil getvcp 10 --bus "$busnum" --terse 2>/dev/null \
        | grep -q "^VCP" && echo "$busnum" > "$tmpdir/$busnum") &
    done
    wait
    export _DDC_BUSES=$(cat "$tmpdir"/* 2>/dev/null | sort -n | xargs)
    rm -rf "$tmpdir"
  fi
  echo "$_DDC_BUSES"
}

br() {
  local val=${1:-50}
  local buses
  buses=$(_ddc_buses)
  if [ -z "$buses" ]; then
    echo "No DDC/CI displays found" >&2
    return 1
  fi
  for bus in $buses; do
    echo "Setting $bus brightness to ${val}%"
    ddcutil setvcp 10 "$val" --bus "$bus"
  done
}

ct() {
  local val=${1:-75}
  local buses
  buses=$(_ddc_buses)
  if [ -z "$buses" ]; then
    echo "No DDC/CI displays found" >&2
    return 1
  fi
  for bus in $buses; do
    echo "Setting $bus contrast to ${val}%"
    ddcutil setvcp 12 "$val" --bus "$bus"
  done
}
