%% Main script to preprocesses DBS imaging data

% run this script if you are done imaging for the day and wanna preprocess
% imaging data
% script calls all preprocessing functions (fix msCam/folder names & 
% concatenates imaging videos)

clear all
close all

% ask use to select folders
main_dir = func_select_folder;


% ask user for filename
file_nm = input('What addition do you want to add to .tif file besides animal name: ', 's');

% ask user what frame to start for every .avi file
frame_start = input('What frame number do you want to start with (1 = first frame)?: ');

% ask use about framerate
fps = input('What is the framerate you recorded with (fps)?: ');


% actually run functions
for k=1:size(main_dir,1)
    tic
    
    %display folder that is running
    fprintf('Folder that we are working on:\n %s\n', main_dir{k})
    cd([main_dir{k}])
    
    % fix number of characters folder names
    cd('imaging\raw')
    func_miniscope_fix_folders(main_dir{k});
    
    % fix number of characters folder names
    func_miniscope_fix_msCam(main_dir{k});
    
    % concat videos
    func_miniscope_concat(main_dir{k},fps,frame_start,file_nm);
    
    % display time to find frames
    fprintf('Time to calculate trial onset, offset, and missing frames for animal %.0f: %.1f sec\n\n', k, toc)
    
    
end

'Done!'









