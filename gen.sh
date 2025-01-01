declare -a labels ids
for file in source/*.svg; do
  echo $file
  mapfile -t -O ${#labels[@]} labels < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@inkscape:label' $file)
  mapfile -t -O ${#ids[@]} ids < <(xml sel -t -v '//*[@inkscape:groupmode="layer"]/@id' $file)
done
labelsLength=${#labels[@]}
idsLength=${#ids[@]}
for (( i=0; i<${labelsLength}; i++ )); do
  label="${labels[$i]}"
  name="$(cut -d ' ' -f 1 <<< $label)"
  x=$(cut -d ' ' -f 2 <<< $label)
  y=$(cut -d ' ' -f 3 <<< $label)
  id="${ids[$i]}"
  echo $name, $x, $y, $id
  # for size in $(seq 12 6 72) ; do
  # 	echo $size
  # done
done
