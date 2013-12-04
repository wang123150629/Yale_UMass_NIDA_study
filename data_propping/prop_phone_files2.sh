#!/usr/bin/env bash

subject_id=$1
file_name=$2

echo ${subject_id}
for i in /home/anataraj/NIH-craving/ecg_data/${subject_id}/* ; do
	if [ -d "$i" ]; then
		cd $i
		echo $i
		for j in 2013* ; do
			if [ -d "$j" ]; then
				echo $j
				filecounter=1
				for k in $j/${file_name}*.csv ; do
					echo $k
					if [ $filecounter -eq 1 ]; then
						echo timestamp, ecg > $j/$j'_ECG'.csv
					fi
					cat $k >> $j/$j'_ECG'.csv
					filecounter=$[$filecounter +1]
				done
			fi
		done
		echo ===============================
	fi
done

