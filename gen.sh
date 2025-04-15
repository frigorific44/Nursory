#!/bin/bash

# Inkscape CLI action combinations.
clear_action="select-all:layers;object-set-attribute:style,display:none;select-clear;"
reveal_action="object-set-attribute:style,display:inline;"

# Greatest common denominator
gcd () {
  if (( $1 % $2 == 0)); then
    echo $2
  else
    gcd $2 $(( $1 % $2 ))
  fi
}
# Least common multiple
lcm () {
  d=$(gcd $1 $2)
  echo $(( $1 * $2 / $d))
}

declare -a layer_labels layer_ids
for file in source/*.svg; do
  echo $file
  mapfile -t -O ${#layer_labels[@]} layer_labels < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@inkscape:label' $file)
  mapfile -t -O ${#layer_ids[@]} layer_ids < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@id' $file)
done
# labelsLength=${#layer_labels[@]}
# idsLength=${#ids[@]}

# Pre-process animation times.
declare -A t_totals t_curr
gcd_v=0

for (( i=0; i<${#layer_labels[@]}; i++ )); do
  label="${layer_labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  t=$(cut -d ' ' -f 4 <<< $label)
  if [ ${#t} != 0 ]; then
    gcd_v=$(gcd $gcd_v $t)
    t_curr["$name"]=0
    if [[ -n "${t_totals["$name"]}" ]]; then
      curr_total="${t_totals["$name"]}"
      t_totals["$name"]=$(( $curr_total + $t))
    else
      t_totals["$name"]=$t
    fi
  fi
done
lcm_v=1
for name in ${!t_totals[@]}; do
  lcm_v=$(lcm $lcm_v "${t_totals[${name}]}")
done
echo GCD: $gcd_v
echo Timing Totals: ${t_totals[@]}
echo LCM: $lcm_v

# If the directory existed previously, clear its contents for consistency.
rm -r assets/*
mkdir -p assets/images assets/config assets/prev_frames

declare -a actions_by_frame
for n in $(seq $gcd_v $gcd_v $lcm_v); do
  actions_by_frame+=("")
done

# Generate assets.
unique=0
for (( i=0; i<${#layer_labels[@]}; i++ )); do
  label="${layer_labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  x=$(cut -d ' ' -f 2 <<< $label)
  y=$(cut -d ' ' -f 3 <<< $label)
  t=$(cut -d ' ' -f 4 <<< $label)
  id="${layer_ids[$i]}"
  echo $name, $x, $y, $id
  cfile="assets/config/${name}.cursor"
  touch "${cfile}"
  target="select-by-id:${id};"
  for size in $(seq 12 12 72) ; do
    f="assets/images/${unique}.png"
    xscaled=$(($x*$size/96))
    yscaled=$(($y*$size/96))
    inkscape source/cursors.svg -o $f -w $size -h $size -D --actions "${clear_action}${target}${reveal_action}"
    echo "$size $xscaled $yscaled $f $t" >> $cfile
    ((unique++))
  done
  if [ ${#t} != 0 ]; then
    for j in $(seq ${t_curr["$name"]} ${t_totals["$name"]} $(($lcm_v - 1))); do
      index=$(($j / $gcd_v))
      echo Frame: $index
      actions_by_frame[$index]="${actions_by_frame[$index]}${target}"
    done
    t_curr["$name"]=$((t_curr["$name"]+$t))
  fi
done

# Generate preview.
mux_cmd="webpmux -frame assets/prev_frames/bg.webp"
f_delay=1
f_id=0
for frame_actions in ${actions_by_frame[@]}; do
  if [ ${#frame_actions} != 0 ]; then
    actions="${clear_action}${frame_actions}${reveal_action}"
    inkscape source/cursors.svg -o "assets/prev_frames/${f_id}.png" -d 192 --actions "$actions"
    mux_cmd="${mux_cmd} +${f_delay} -frame assets/prev_frames/${f_id}.webp"
    f_delay=0
    ((f_id++))
  fi
  f_delay=$((f_delay+gcd_v))
done
inkscape source/cursors.svg -o "assets/prev_frames/bg.png" -d 192
mux_cmd="${mux_cmd} +${f_delay} -bgcolor 0,0,0,0 -o preview.webp"
# As of writing, files cannot be exported to webp format in the CLI,
# hence the circuitous conversions.
for f in ./assets/prev_frames/*.png; do
  magick "$f" "${f%.*}.webp"  
done
$mux_cmd

# If the directory existed previously, clear its contents for consistency.
rm -r dist/cursors/*
mkdir -p dist/cursors
# Package assets into cursor files.
for path in ./assets/config/*.cursor; do
  base="${path##*/}"
  name="${base%.*}"
  xcursorgen $path "dist/cursors/${name}"
done
# Adds symbolic links to fill in missing cursors.
./addmissing.sh
