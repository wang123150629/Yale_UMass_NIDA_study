#!/usr/bin/env bash

subject_id=$1

echo ${subject_id}
for i in /home/anataraj/NIH-craving/data/${subject_id}/* ; do
	if [ -d "$i" ]; then
		cd $i
		echo $i
		for j in "$i"/201* ; do
			if [ -d "$j" ]; then
				cd $j
				echo $j
				echo `head -2 $j/*ECG.csv`
				echo `tail -1 $j/*ECG.csv`
				echo ---------------------------
			fi
		done
		echo ===============================
	fi
done

