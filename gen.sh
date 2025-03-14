declare -a labels ids
for file in source/*.svg; do
  echo $file
  mapfile -t -O ${#labels[@]} labels < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@inkscape:label' $file)
  mapfile -t -O ${#ids[@]} ids < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@id' $file)
done
labelsLength=${#labels[@]}
idsLength=${#ids[@]}
# If the directory existed previously, clear its contents for consistency.
rm -r assets/*
mkdir assets assets/images assets/config
unique=0
for (( i=0; i<${labelsLength}; i++ )); do
  label="${labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  x=$(cut -d ' ' -f 2 <<< $label)
  y=$(cut -d ' ' -f 3 <<< $label)
  id="${ids[$i]}"
  echo $name, $x, $y, $id
  cfile="assets/config/${name}.cursor"
  > "${cfile}"
  for size in $(seq 12 12 72) ; do
    f="assets/images/${unique}.png"
    xscaled=$(($x*$size/96))
    yscaled=$(($y*$size/96))
    inkscape source/cursors.svg -o $f -w $size -h $size -D --actions "select-all:layers; object-set-attribute:style, display:none; select-clear; select-by-id:${id}; object-set-attribute:style, display:inline"
    echo "$size $xscaled $yscaled $f" >> $cfile
    ((unique++))
    # echo $unique
  done
done
# If the directory existed previously, clear its contents for consistency.
rm -r dist/cursors/*
mkdir dist dist/cursors
for path in ./assets/config/*.cursor; do
  base="${path##*/}"
  name="${base%.*}"
  xcursorgen $path "dist/cursors/${name}"
done
./addmissing.sh
