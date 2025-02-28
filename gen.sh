declare -a labels ids
for file in source/*.svg; do
  echo $file
  mapfile -t -O ${#labels[@]} labels < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@inkscape:label' $file)
  mapfile -t -O ${#ids[@]} ids < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@id' $file)
done
labelsLength=${#labels[@]}
idsLength=${#ids[@]}
mkdir assets
unique=0
for (( i=0; i<${labelsLength}; i++ )); do
  label="${labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  x=$(cut -d ' ' -f 2 <<< $label)
  y=$(cut -d ' ' -f 3 <<< $label)
  id="${ids[$i]}"
  echo $name, $x, $y, $id
  inkscape source/cursors.svg -o "assets/${name}.png" --actions "select-all:layers; object-set-attribute:style, display:none; select-clear; select-by-id:${id}; object-set-attribute:style, display:inline"
  for size in $(seq 12 6 72) ; do
    ((unique++))
    # echo $unique
  done
done
