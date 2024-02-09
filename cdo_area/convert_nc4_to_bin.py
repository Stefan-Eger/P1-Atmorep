import os
import sys
import netCDF4
import numpy as np


def convert_file(filepath):
    print("Processing " + filepath + "...")
    file = netCDF4.Dataset(filepath + '.nc4')

    # output dimension (timestamp, model_level, lat, lon)
    mean = file.variables['mean'][:]
    std = file.variables['std'][:]
    if(len(mean.shape) == 3 and len(std.shape) == 3):
        output = np.stack((mean[0].data, std[0].data), axis=2)
    else:
        output = np.stack((mean[0][0].data, std[0][0].data), axis=2)

    #print(f"output shape: {output.shape}")

    output.astype('float32').tofile(filepath + ".bin")

    # comment this line if .nc4 files should remain
    os.remove(filepath + '.nc4')



def create_filepaths(year: int, variable_name: str, level: int):
    filepaths = []

    fdir_base = 'normalization/{}/{}{}/'
    fname_base = 'normalization_mean_var_{}_y{}_m{:02d}_{}{}'

    filedir = fdir_base.format(variable_name, 'ml', level)

    for month in range(1, 12 + 1):
        filename = fname_base.format(variable_name, year, month, 'ml', level)
        filepaths.append(filedir + filename)
    return filepaths


def convert_nc4_to_bin():
    print(f"Arguments: {sys.argv[1:]}")
    years = list(map(int, sys.argv[1].split(',')))
    variable_name = sys.argv[2]
    levels = list(map(int, sys.argv[3].split(',')))

    print(f"YEARS: {years}")
    print(f"VARIABLE_NAMES: {variable_name}")
    print(f"MODEL_LEVELS: {levels}")

    for year in years:
        for level in levels:
            filepaths = create_filepaths(year, variable_name, level)
            for filepath in filepaths:
                convert_file(filepath)
            print(f"FINISHED YEAR{year} - ml{level}")


# Arguments YEARS, VARIABLENAME MODEL_LEVELS
# example 
# python3 convert_nc4_to_bin.py 1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2018 T 35,36,37,38,39,40
if __name__ == '__main__':
    convert_nc4_to_bin()
