#!/usr/bin/env bash

subject_id=$1
file_name=$2

echo ${subject_id}
for i in /home/anataraj/NIH-craving/data/missing_data_subjects/${subject_id}/phoneecg/*${file_name}.csv ; do
	echo $i
	echo `head -2 $i`
	echo `tail -1 $i`
	sed -i 's/:/,/g' $i
	sed -i 's:/:,:g' $i
	sed -i 's:-:,:g' $i
	sed -i 's/ /,/g' $i
	echo `head -2 $i`
	echo `tail -1 $i`
	echo ===============================
done

