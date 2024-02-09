#!/bin/bash
START_TIME=$SECONDS

#change as necessary
OLD_VARNAME=var34
VARNAME=V
YEAR=2017
N=32		#Tasks simultaniously allowed
declare -a LEVELS=(35 36 37 38 39 40) 

#do not change
SRC_DIR=./"$VARNAME"/"$YEAR"
DST_DIR=./"$VARNAME"/"$YEAR"
ML_DST_DIR=./"$VARNAME"
FILE_PREFIX="$VARNAME".3D."$YEAR"

declare -a MONTHS=(01 02 03 04 05 06 07 08 09 10 11 12)

if [ ! -d "$SRC_DIR" ]; then
	echo "Error: Source directory does not exist"
	echo "$SRC_DIR"
	exit 1
fi

# checking if destination directory exists if not it will be created
if [ ! -d "$DST_DIR" ]; then
	echo "DST_DIR is being created"
	mkdir -p "$DST_DIR"
fi


merge_files(){
	echo "Month Data $1* will be merged to $2"
	cdo -f nc4 mergetime "$1*" "$2.nc4"
	rm -f "$1"*
}

chname_files(){
	
	filename=$(basename "$1")
	filename="${filename%.*}"
	
	cdo chname,"$2","$3" "$1" "$DST_DIR/${filename}_.nc4"
	rm "$1"
}
select_level(){
	
	filename=$(basename "$1")
	filename="${filename%.*}"

	for level in "${LEVELS[@]}"; do 
	
		if [ ! -d "$ML_DST_DIR/ml${level}" ]; then
			echo "ml$level Dir is being created"
			mkdir -p "$ML_DST_DIR/ml${level}"
		fi
	
		cdo sellevel,"$level" $1 "$ML_DST_DIR/ml${level}/${filename}ml$level.nc4"
	done
	
	rm "$1"
}

#Merging all hour files to a single month file
echo "merge hours to month.nc4"
(
for month in "${MONTHS[@]}"; do 
   ((i=i%N)); ((i++==0)) && wait
	merge_files "$SRC_DIR/$FILE_PREFIX$month" "$DST_DIR/cosmo_${VARNAME}_y${YEAR}_m${month}" &
done; wait
) & all_months=$!

wait $all_months


#updating variable Name for later extraction
echo "Update Variable Name"
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	chname_files "$file" "$OLD_VARNAME" "$VARNAME" &
done; wait
) & all_vars=$!

wait $all_vars

#separating model Levels for atmorep
echo "Select Model Level ml<level>"
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	select_level "$file" &
done; wait
) & all_vars=$!

wait $all_vars
echo "FINISHED: "$YEAR""
#output duration
duration=$(($SECONDS - $START_TIME))
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
