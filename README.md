# Miniscope_prepare_data_preprocessing
Prepare Miniscope V3 data before preprocessing (NoRMCorre and CNMF-E), used in the Willuhn lab at the Netherlands Institute for Neuroscience. 

These functions prepare Miniscope V3 recorded data per sessions to be able to easily preprocess the data using NoRMCorre and CNMF-E). 

Folders must be organized ...\animal\session\imaging\raw\miniscope_recording_folders [imaging and raw need to be named like that, or change line 34!].
miniscope_recording_folders need to be Miniscope V3 sub folders (e.g., H14_M24_S1) with imaging data (e.g., msCam1.avi and msCam2.avi) and timestamps of imaging frame (i.e., timestamp.dat).

Important script
- universal_miniscope_preprocessing: runs all the function

Options
- asks user to select one folder or all folders with a given extension in a main folder
- asks user what additional name .tiff file should get (besides animal's name and session)
- asks user what frame to start with (1=first frame, but maybe you want to consistently skip 3 frames due to onset artifacts)
- asks user what framerate was used during imaging
- func_miniscope_fix_folders: makes sure each folder's name will be 11 characters (e.g., H14_M24_S1 will become H14_M24_S01), this is important for Matlab to keep track of the chronological order of imaging
- func_miniscope_fix_msCam: makes sure each recorded .avi file will be 7 characters (e.g., msCam1.avi will become msCam01.avi), this is important if you have long recordings for Matlab to keep track of chronological order of imaging
- func_miniscope_concat: concatenates all .avi files (within a sub folder and over each session) into one .tiff file, in addition, it calculates (using FPS and timestamp.dat files) where missing frames have occured

Output
- one .tiff file per animal per recording that can be used to preprocess imaging data
- one .mat file with missing frames:
- frames.start_frame indicates what frame number per recording was used to start concatenating
- frames.file_list shows which folders/files have been used to concatenate
- frames.trial_structure indicate which frames belong to which recording and where missing frames can be found
- columns are individual recordings (e.g., H14_M24_S1)
- first row is start frame of individual recordings in the concatenated .tiff file
- second row is stop frame of individual recordings in the concatenated .tiff file
- third row is total number of frames of individual recordings in the concatenated .tiff file
- any next row shows location of missing frame (e.g., frame 400). if you find replicates (e.g., 400 400 400 400 400), you have 5 missing frames at location 400




Preprocessing pipeline used to preprocess Miniscope data (NoRMCorre and CNMF-E) in the Willuhn lab at the Netherlands Institute for Neuroscience.

One can run preprocessing for a given session (single mode) or number of sessions consecutive (batch mode). For both options, it runs NoRMCorre on every video, saves non-rigid tiff file, and uses that to run CNMF-e.

Important scripts

    cai_pipeline_bastijn: single mode
    cai_pipeline_bastijn_batch: batch mode

Optional scripts

    cai_pipeline_bastijn_batch_cnmfe_videos: same as cai_pipeline_bastijn, but in addition saves denoised and demixed video. Run this on a small video file (~1000 frames).
    only_cnmf_e_bastijn: only run CNMF-E (use this if CNMF-E keeps crashing during certain session and you want to manually get the right parameters)

This pipeline makes use of another package (included in this folder):

- rharkes's Fast_Tiff_Write (https://github.com/rharkes/Fast_Tiff_Write)

