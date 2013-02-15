#!/usr/bin/env bash

subject_id=$1
file_name=$2

echo ${subject_id}
for i in /home/anataraj/NIH-craving/data/${subject_id}/* ; do
	if [ -d "$i" ]; then
		cd $i
		echo $i
		for j in "$i"/201* ; do
			if [ -d "$j" ]; then
				cd $j
				echo $j
				echo `head -2 $j/*${file_name}.csv`
				echo `tail -1 $j/*${file_name}.csv`
				sed -i 's/:/,/g' *${file_name}.csv
				sed -i 's:/:,:g' *${file_name}.csv
				sed -i 's:-:,:g' *${file_name}.csv
				sed -i 's/ /,/g' *${file_name}.csv
				echo `head -2 $j/*${file_name}.csv`
				echo `tail -1 $j/*${file_name}.csv`
			fi
		done
		echo ===============================
	fi
done

