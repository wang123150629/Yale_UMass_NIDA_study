#!/usr/bin/env bash

subject_id=$1
file_name=$2

echo ${subject_id}
for i in /home/anataraj/NIH-craving/ecg_data/${subject_id}/* ; do
	if [ -d "$i" ]; then
		cd $i
		echo $i
		for j in "$i"/201* ; do
			if [ -d "$j" ]; then
				cd $j
				echo $j
				filecounter=1
				for k in *${file_name}.csv ; do
					echo $k
					if [ $filecounter -eq 1 ]; then
						cat $k > output.csv
					else
						tail -n +2 $k >> output.csv
					fi
					filecounter=$[$filecounter +1]
				done
			fi
		done
		echo ===============================
	fi
done

