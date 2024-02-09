#!/bin/bash

START_TIME=$SECONDS

SRC_DIR=./T/1995
DST_DIR=./T/1995
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

unpack_tar(){
	#echo "$1 will be unpacked"
	#tar -xvf "$1" -C "$DST_DIR"
	tar -xf "$1" -C "$DST_DIR"
	
	rm "$1"
}

rotate_grid(){
	#echo "$1 will be rotated"
	cdo -f nc4 -z zip=9 -copy -setgrid,"$REA6_GRID" "$1" "$1.nc4"
	rm "$1"
}
cut_out(){
	#echo "$1 will be cut out"
	cdo sellonlatbox,"$LON1","$LON2","$LAT1","$LAT2" "$1" "$1.nc4"
	rm "$1"
}



# Loops over each zipped file in the SRC_DIR.
echo "unpack tar files..."
(
for file in "$SRC_DIR"/*; do 
   ((i=i%N)); ((i++==0)) && wait
	unpack_tar "$file" &
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

echo "FINISHED: "$SRC_DIR""
#output duration
duration=$(($SECONDS - $START_TIME))
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
