#!/bin/bash

START_TIME=$SECONDS

YEAR=2017
VARNAME=U
N=32
declare -a LEVELS=(ml35 ml36 ml37 ml38 ml39 ml40) 

SRC_DIR="$VARNAME"
NORM_DIR=normalization/"$VARNAME"/
IN_FILE_PREFIX="cosmo_${VARNAME}_y${YEAR}"
OUT_FILE_PREFIX="normalization_mean_var_${VARNAME}_y${YEAR}"
declare -a MONTHS=(01 02 03 04 05 06 07 08 09 10 11 12)

if [ ! -d "$SRC_DIR" ]; then
	echo "Error: Source directory does not exist"
	echo "$SRC_DIR"
	exit 1
fi

# checking if destination directory exists if not it will be created
if [ ! -d "$NORM_DIR" ]; then
	echo "NORM_DIR is being created $NORM_DIR"
	mkdir -p "$NORM_DIR"
fi

merge_mean_std(){
	cdo merge $1 $2 $3
	rm $1 $2
}

chname_variable(){
	cdo chname,"$VARNAME",$2 "$1" "$3"
	rm $1
}

calc_mean_and_std_all_months_per_year(){
	mean_filename="${2}_mean.nc4"
	mean_filename_named="${2}_mean_named.nc4"
	
	std_filename="${2}_std.nc4"
	std_filename_named="${2}_std_named.nc4"

	cdo monmean "$1.nc4" "$mean_filename"
	cdo monstd "$1.nc4" "$std_filename"
	
	chname_variable "$mean_filename" "mean" "$mean_filename_named"
	chname_variable "$std_filename" "std" "$std_filename_named"
	
	merge_mean_std "$mean_filename_named" "$std_filename_named" "$2.nc4"
}

#calculating mean and std for all month in a given year for all model levels
echo "Calculating mean and std for $YEAR"
(
for level in "${LEVELS[@]}"; do
	DST_DIR="$NORM_DIR/$level"	
	
	if [ ! -d "$DST_DIR" ]; then
		echo "DST_DIR is being created $DST_DIR"
		mkdir -p "$DST_DIR"
	fi
	
	for month in "${MONTHS[@]}"; do 
		((i=i%N)); ((i++==0)) && wait
		calc_mean_and_std_all_months_per_year "$SRC_DIR/$level/${IN_FILE_PREFIX}_m${month}_${level}" "$DST_DIR/${OUT_FILE_PREFIX}_m${month}_${level}" &
	done
done; wait
) & all_levels=$!

wait $all_levels


echo "FINISHED: "$YEAR""
#output duration
duration=$(($SECONDS - $START_TIME))
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
