#!/bin/bash

START_TIME=$SECONDS

OLD_VARNAME=var61
VARNAME=TOT_PRECIP

SRC_DIR=./$VARNAME
DST_DIR=./$VARNAME
REA6_GRID=./griddes_REA6.txt
LON1=4
LON2=22
LAT1=40
LAT2=55
N=32


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

unpack_bzip(){
	#echo "$1 will be unpacked"
	#tar -xvf "$1" -C "$DST_DIR"
	#tar -xf "$1" -C "$DST_DIR"
	bzip2 -d "$1"
}

rotate_grid(){
	#echo "$1 will be rotated"
	cdo -f nc4 -z zip=9 -copy -setgrid,"$REA6_GRID" "$1" "$1.nc4"
	rm "$1"
}
cut_out(){
	
	cdo sellonlatbox,"$LON1","$LON2","$LAT1","$LAT2" "$1" "$1.nc4"
	rm "$1"
}

chname_files(){
	
	filename=$(basename "$1")
	filename="${filename%.*.*.*}" 	#remove extensions
	filename="${filename#*.*.}"		#remove previous dots until year and month are left
	year="${filename:0:4}"
	month="${filename:4:6}"
	
	#echo "YEAR: $month"
	
	if [ ! -d "$DST_DIR/ml0" ]; then
		echo "DST_DIR is being created"
		mkdir -p "$DST_DIR/ml0"
	fi
	
	cdo chname,"$2","$3" "$1" "$DST_DIR/ml0/cosmo_${VARNAME}_y${year}_m${month}_ml0.nc4"
	rm "$1"
}



# Loops over each zipped file in the SRC_DIR.
echo "unpack bzip files..."
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	unpack_bzip "$file" &
done; wait
) & all_tars=$!

wait $all_tars

# Loops over each grib file in the SRC_DIR and rotates the grid.
echo "rotate grids..."
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	rotate_grid "$file" &
done; wait
) & all_rotations=$!

wait $all_rotations

# Loops over each nc4 file in the SRC_DIR and cuts out specified Longitude and Latitude.
echo "cutting out specified Longitude and Latitude..."
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	cut_out "$file" &
done; wait
) & all_cuts=$!

wait $all_cuts

#updating variable Name for later extraction
echo "Update Variable Name"
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	chname_files "$file" "$OLD_VARNAME" "$VARNAME" &
done; wait
) & all_vars=$!

wait $all_vars
echo "FINISHED: "$SRC_DIR""
#output duration
duration=$(($SECONDS - $START_TIME))
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
