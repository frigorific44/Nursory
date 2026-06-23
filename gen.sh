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

### Parse the layer names and ids.
# 
# The layer names encode cursor configuration info and timings.
# IDs are used to reference layers in Inkscape commands.
declare -a layer_labels layer_ids layer_files
sources=(source/*.svg)
for i in "${!sources[@]}"; do
  file="${sources[$i]}"
  echo $file
  prev_len=${#layer_labels[@]}
  mapfile -t -O ${#layer_labels[@]} layer_labels < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@inkscape:label' $file)
  mapfile -t -O ${#layer_ids[@]} layer_ids < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@id' $file)
  n_added=$((${#layer_labels[@]} - $prev_len))
  for (( j=0; j<$n_added; j++ )); do
    layer_files+=($i)
  done
done

### Pre-process animation times.
# 
# Associative arrays to the cumulative length of a cursor's animation.
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
for name in "${!t_totals[@]}"; do
  lcm_v=$(lcm $lcm_v "${t_totals[${name}]}")
done
echo GCD: $gcd_v
echo Timing Totals: ${t_totals[@]}
echo LCM: $lcm_v

### Generate assets.
# 
# If the directory existed previously, clear its contents for consistency.
rm -r assets/*
mkdir -p assets/images assets/config assets/prev_frames
# actions_by_frame accumulates actions to include all layers relevant
# to the animation frame of the preview animation.
declare -a actions_by_frame
frames=$(($lcm_v / gcd_v))
for x in $(seq $frames); do
  for y in "${!sources[@]}"; do
    actions_by_frame+=("")
  done
done

unique=0
for (( i=0; i<${#layer_labels[@]}; i++ )); do
  label="${layer_labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  x=$(cut -d ' ' -f 2 <<< $label)
  y=$(cut -d ' ' -f 3 <<< $label)
  t=$(cut -d ' ' -f 4 <<< $label)
  id="${layer_ids[$i]}"
  source_index="${layer_files[$i]}"
  source_file="${sources[$source_index]}"
  echo $name, $x, $y, $id
  cfile="assets/config/${name}.cursor"
  touch "${cfile}"
  target="select-by-id:${id};"
  for size in $(seq 12 12 72) ; do
    f="assets/images/${unique}.png"
    xscaled=$(($x*$size/96))
    yscaled=$(($y*$size/96))
    inkscape "$source_file" -o $f -w $size -h $size -D --actions "${clear_action}${target}${reveal_action}"
    echo "$size $xscaled $yscaled $f $t" >> $cfile
    ((unique++))
  done
  if [ ${#t} != 0 ]; then
    for j in $(seq ${t_curr["$name"]} ${t_totals["$name"]} $(($lcm_v - 1))); do
      offset=$(($source_index * $frames))
      frame=$(($j / $gcd_v))
      index=$(($offset + $frame))
      echo Frame: $frame
      actions_by_frame[$index]="${actions_by_frame[$index]}${target}"
    done
    t_curr["$name"]=$((t_curr["$name"]+$t))
  else
    # offset=$(($source_index * $frames))
    actions_by_frame[0]="${actions_by_frame[0]}${target}"
  fi
done

# Generate preview.
preview_dpi=192
mux_cmd="webpmux"
f_delay=0
for frame in $(seq $frames); do
  empty_frame=0
  for source_index in "${!sources[@]}"; do
    empty_frame=1
    offset=$(($source_index * $frames))
    index=$(($offset + $frame - 1))
    frame_actions=${actions_by_frame[$index]}
    if [ ${#frame_actions} != 0 ]; then
      actions="${clear_action}${frame_actions}${reveal_action}"
      file_name="assets/prev_frames/${frame}-${source_index}.png"
      inkscape "${sources[$source_index]}" -o "${file_name}" -d $preview_dpi --actions "$actions"
      f_delay=0
    fi
  done
  f_delay=$(($f_delay+$gcd_v))
  if (( "$frame" == "1" )); then
    f_delay=1
  fi
  if [ $empty_frame -ne 0 ]; then
    magick "assets/prev_frames/${frame}-*.png" -background "rgba(0, 0, 0, 0.0)" -layers flatten "assets/prev_frames/${frame}.webp"
    mux_cmd="${mux_cmd} +${f_delay} -frame assets/prev_frames/${frame}.webp"
  fi
done
mux_cmd="${mux_cmd/ +1 / }"
mux_cmd="${mux_cmd} +${f_delay} -bgcolor 0,0,0,0 -o preview.webp"
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
