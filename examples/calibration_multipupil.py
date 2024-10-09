#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import numpy as np
from tkinter import Tk, simpledialog
from tkinter.filedialog import askopenfilename, askdirectory
from pathlib import PureWindowsPath
from dmlib.calibration import RegLSCalib
from dmlib.interf import FringeAnalysis
from h5py import File
"""Using dmlib to compute a calibration for multiple pupil radii.

This script allows the user to select an HDF5 file containing interferometric data,
specify multiple pupil radii for calibration, and choose an output directory for the
calibration files. The script will compute the calibration for each specified pupil
radius and save the results in the chosen output directory.

Steps:
1. Download the HDF5 file containing interferometric data.
2. Run this script to select the HDF5 file and specify the output directory.
3. Enter the list of pupil radii (comma-separated, in micrometers) when prompted.
4. The script will compute the calibration for each radius and save the results.

The output files will be named based on the DM name extracted from the HDF5 file name
and the specified pupil radius. For example, if the DM name is "17BW023#017" and the
specified radii are 1400 and 1600 micrometers, the following files will be generated:

- 17BW023#017_1.400mm_CAL_Z0_vector.dat
- 17BW023#017_1.400mm_CAL_C_matrix.dat
- 17BW023#017_1.600mm_CAL_Z0_vector.dat
- 17BW023#017_1.600mm_CAL_C_matrix.dat

"""

if __name__ == '__main__':  # necessary for multiprocessing
    # Hide the root window
    Tk().withdraw()
    
    # Open file dialog to select the .h5 file
    file_path = askopenfilename(filetypes=[("HDF5 files", "*.h5")])
    
    if not file_path:
        raise ValueError("No file selected")
    
    # Open file dialog to select the output directory
    output_directory = askdirectory()
    
    if not output_directory:
        raise ValueError("No output directory selected")
    
    # Get the list of radii from the user using a tkinter dialog
    radii_input = simpledialog.askstring("Input", "Enter the list of pupil radii (comma-separated, in um):")
    if not radii_input:
        raise ValueError("No radii entered")
    
    radii = [int(r.strip()) for r in radii_input.split(',')]
        
    # Convert the file path to a PureWindowsPath object
    path = PureWindowsPath(file_path)
    
    # Extract the directory and file name
    directory = path.parent
    fname = path.name

    # Extract DMName from fname
    for delimiter in ['_', '-']:
        if delimiter in fname:
            DMName = fname.split(delimiter)[0]
            break
    else:
        raise ValueError("Filename does not contain an underscore or dash to extract DMName")
    
    # load the interferograms from the HDF5 file
    with File(os.path.join(directory, fname), 'r') as f:
        align = f['align/images'][()]
        names = f['align/names'][()]
        if isinstance(names, bytes):
            names = names.decode()
        images = f['data/images'][()]
        cam_pixel_size_um = f['cam/pixel_size'][()]
        U = f['data/U'][()]
        wavelength_nm = f['wavelength'][()]

    # pull an interferogram with all actuators at rest
    img_zero = images[0, ...]
    # pull an interferogram where the central actuators have been poked
    img_centre = align[names.index('centre'), ...]

    # make a fringe analysis object
    fringe = FringeAnalysis(images[0, ...].shape, cam_pixel_size_um)

    # use img_zero to lay out the FFT masks
    fringe.analyse(img_zero,
                   auto_find_orders=True,
                   do_unwrap=True,
                   use_mask=False)

    # loop through radii
    for pupil_radius in radii:
        # calculate the image center based on the largest aperture
        fringe.estimate_aperture(img_zero, img_centre, pupil_radius)
        
        # compute the calibration
        calib = RegLSCalib()
        calib.calibrate(U, images, fringe, wavelength_nm, cam_pixel_size_um, status_cb=print)
        
        # save the calibration to a file
        endingH5 = f'{DMName}_{pupil_radius}um_CAL.h5'
        #ending = f'calib_{pupil_radius}.h5'
        foutname = os.path.join(output_directory, endingH5)
        with File(foutname, 'w', libver='latest') as h5f:
            calib.save_h5py(h5f)
        
        # save the relevant parameters for AO in Slidebook
        pupil_radius_mm = pupil_radius / 1000
        endingZ0 = f'{DMName}_{pupil_radius_mm:.3f}mm_CAL_Z0_vector.dat'
        foutnameZ0 = os.path.join(output_directory, endingZ0)
        np.savetxt(foutnameZ0, calib.z0, fmt="%s")
        
        endingC = f'{DMName}_{pupil_radius_mm:.3f}mm_CAL_C_matrix.dat'
        foutnameC = os.path.join(output_directory, endingC)
        np.savetxt(foutnameC, calib.C, fmt="%s")

        endingU0 = f'{DMName}_{pupil_radius_mm:.3f}mm_CAL_U0_vector.dat'
        foutnameU0 = os.path.join(output_directory, endingU0)
        np.savetxt(foutnameU0, calib.uflat, fmt="%s")
        # Save U0 vector with each value on one line, separated by a space
        # np.savetxt(foutnameU0, calib.uflat.reshape(1, -1), fmt="%s", delimiter=' ')