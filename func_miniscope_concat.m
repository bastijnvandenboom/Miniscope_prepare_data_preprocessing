%% script to concatenate Miniscope .avi videos and read timestamp.dat files for complete folder

% put all Miniscope sub directories in one main directory
% e.g. main: animal1, sub: H12_M44_S30, H12_M44_S58, H12_M45_S22
% these sub's contain the recordings (e.g. msCam1, msCam2) and
% timestamp.dat files

% script first asks for how many main directories you want to load
% script then asks you to select every directory you want to load one by one
% concatenates videos and outputs .tif file in a new folder (concatenated)
% also outputs trial onset & offset and missing frames (>75ms between
% frames)

% input: .avi & timestamp.dat
% output: .tif & .mat (trial structure, missing frames, order
% concatenating, and number first frame loaded)
% frames.trial_structure: columns are trials
%   row1: trial onset
%   row2: trial offset
%   row3: number of frames in trial
%   row4 and lower: missing frame location
% frames.file_list: to check order of concatenating
% frames.start_frame: first frame loaded


% 20210507 check if between low value frames, there are actually good
% frames or not (lines 160-171)


function func_miniscope_concat(animal_dir,fps,frame_start,file_nm)

% name of tif output file
vid_nm = [file_nm, '.tif'];

% start loop to run through directories

% for d = 1:length(main_dir)

%Start with concatenating video files

clearvars -except d k kk dialog_title file_nm frame_start main_dir num_dir vid_nm fps animal_dir

% find all directories
file_dir = dir('H*');
file_dir = file_dir([file_dir(:).isdir]==1);

% make list of all .avi videos
idx = 0;
for i=1:size(file_dir,1)
    cd(file_dir(i).name);
    video_nm = dir('*.avi');
    for j=1:size(video_nm,1)
        idx = idx +1;
        file_list(idx,:) = ([file_dir((i)).name '\' video_nm(j).name]);
    end
    cd ..;
end


% find animal's name
animal_nm_split = strsplit(animal_dir,'\');       % add animal name to file
animal_nm = [cell2mat(animal_nm_split(length(animal_nm_split)-1)) '_' cell2mat(animal_nm_split(length(animal_nm_split)))];   % same

% create output in seperate folder
dir_new_name = ['concatenated_' animal_nm];
mkdir(dir_new_name);

% create variables to save frames
image_cell = cell(1,1);   % create cell for tiffs
cropped_image_cell = cell(1,1);    % create cell for cropped tiffs
frame = 1;  %to keep track of frames

% if frame_start is 1 only concat and crop, else also count frames to
% calculate how many to skip

% read all videos (frames)
for i = 1:size(file_list,1)
    
    inputVideo = VideoReader(file_list(i,:));   % load videos in list's order
    
    frame_num = 0;  % frame number for given video
    
    while hasFrame(inputVideo)
        frame_num = frame_num +1;   % count frames per video
        
        if frame_num >= frame_start    % skip first x number of frames if necessary
            image_cell{frame} = readFrame(inputVideo); % read image and store in cell array
            cropped_image_cell{frame} = imresize(image_cell{frame},0.5); % 0.5 means 2x spatial downsampling
            frame = frame + 1;
        else
            readFrame(inputVideo);  % read but don't use
        end
    end
end

%save fast with Fast_Tiff
vid_nm_animal = [animal_nm vid_nm];     % same

cd ([dir_new_name]);
fTIF = Fast_Tiff_Write(vid_nm_animal);

for k = 1:length(cropped_image_cell)
    fTIF.WriteIMG(cropped_image_cell{k}');
end
fTIF.close;

cd ..
%end concatenate video files


%Start with finding missing frames

% make list of all timestamp files
clear file_list
%     cd(animal_dir);
for i=1:size(file_dir,1)
    file_list(i,:) = [file_dir(i).name '\timestamp.dat'];
end

% actually read timestamp files
for i = 1:size(file_list,1)
    
    clear timestamp_file missing_frame_stop missing_frame_start missing_frame_locations missing_frame_total

    % open matrix convert to matrix - MATLAB 2016b works with readtable
    % (followed by table2array), MATLAB 2022b importfile
    try     % 2016b - how it started
        timestamp_file = readtable(file_list(i,:));  % read .dat file
        timestamp_file = table2array(timestamp_file);
    catch   % 2022b - how it's going
        timestamp_file = importdata(file_list(i,:));  % read .dat file
        timestamp_file = timestamp_file.data;
    end
    
    % find missing frames
    for j=1:size(timestamp_file(:,3),1)-1
        timestamp_file(j,5) = timestamp_file(j+1,3) - timestamp_file(j,3);
    end
    
    % find those damn missing frames (emperically found out miniscope
    % tries to fix frames, therefore missing frames generally span
    % multiple frames (you have maybe 8 frames with high
    % recording time, followed by 1 or 2 frames with low recording
    % times)). we use the low recording times to find these bouts. dont
    % include frame 1, 2, or last since they can have low values as
    % well
    
    % find low frame rec frames, delete 1,2,end, and ones close together
    missing_frame_stop = find(timestamp_file(:,5) < ((1000 / fps) / 2)); %gives location of when missing frames end (half the fps)
    
    if exist('missing_frame_stop','var')
    else
        missing_frame_stop = [];
    end
    
    % delete low frame time if first or second frame, or last
    indice = find(missing_frame_stop == 1 | missing_frame_stop == 2 | missing_frame_stop == length(timestamp_file));
    missing_frame_stop(indice) = [];    % delete if missing frame bout end is frame 1, 2, or last frame
    
    % if you find 2 consecutive low frames, delete second
    for j=1:length(missing_frame_stop)-1    % delete the second low ms frame if its consecutive
        if missing_frame_stop(j)+1 == missing_frame_stop(j+1)
            missing_frame_stop(j+1) = NaN;
        end
    end
    missing_frame_stop = missing_frame_stop(~isnan(missing_frame_stop));
    
    
    % check if between low frame values, there are actually good frames
    % (otherwise it's just one big block of crappy frames)
    for j=1:length(missing_frame_stop)-1
        l=1;
        while timestamp_file(missing_frame_stop(j)+l,5) ~= round(1000/fps)-1
            l=l+1;
        end
        if missing_frame_stop(j)+l > missing_frame_stop(j+1)
            missing_frame_stop(j) = NaN;
        end
    end
    missing_frame_stop = missing_frame_stop(~isnan(missing_frame_stop));
    
    
    %go back in time and find number of frames that should be added
    for j=1:length(missing_frame_stop)
        k = missing_frame_stop(j)+1;    %first value is always very low
        l = 0;              %keep track of loops, sporadically 1 frame before low value is normal frame..
        good_value = 1;           % any value would be fine, but not fps
        while good_value ~= round(1000/fps)-1   % keep on looping until you find fps framerate (e.g., 66)
            l=l+1;              %loop tracker
            if l == 2       % we dont want to include the value before the lowest as that can be 66 (emperical found out)
                k=k-1;
                continue
            end
            k=k-1;              % here do the -1 you added 4 lines above
            if k == 1        % if we go as low as the first value, make good_value correct value
                good_value = round(1000/fps)-1;    % to make sure first correct frame is at least frame 1 of recording or higher!
            else
                good_value = timestamp_file(k,5);   %find the 66
            end
        end
        missing_frame_start(j,:) = k;        %k is start frame of missing frames bout
    end
    
    % now calculate how many frames are missing
    if exist('missing_frame_start','var')
        for j=1:length(missing_frame_start)
            missing_frame_total(j,:) = round(sum(timestamp_file(missing_frame_start(j):missing_frame_stop(j)+1,5))/(1000/fps)) - ((missing_frame_stop(j)+1) - missing_frame_start(j)+1);  %sum frames in ms (+1 frame to be sure to capture all crappy frames), divide by frameduration (66.6ms), minus number of frames
        end
    else
        missing_frame_total = [];
        missing_frame_start = [];
    end
    
    % there will be 0's because Miniscope divided ms time between
    % frames and fixed framerate. delete those from _start, _stop,
    % _total
    indice = find(missing_frame_total == 0);
    missing_frame_total(indice) = [];
    missing_frame_start(indice) = [];
    missing_frame_stop(indice) = [];
    
    % somehow get this in a matrix. What i want is how often missing
    % frame occurred (missing_frame_total) copied as its value for
    % location (missing_frame_stop)
    m = 1;  % counter where to parse in _locations
    if missing_frame_total ~= 0
        for j=1:length(missing_frame_total)
            k = 0;  % keep track of parsing missing_frame_stop
            while k ~= missing_frame_total(j)
                missing_frame_locations(m,:) = missing_frame_stop(j);
                k = k + 1;
                m = m + 1;
            end
        end
    else
        missing_frame_locations = [];
    end
    
    
    % find trial on- and offset
    trial_end = max(timestamp_file(:,2));    %find number of recorded frames
    
    % save in matrix
    % maybe: row 1 onset, 2 offset, 3 total frame, 4 and lower location missing frames
    % columns are trials
    if i==1
        trial_structure(1,i) = 1;
        trial_structure(2,i) = trial_end - frame_start + 1;
        trial_structure(3,i) = trial_end - frame_start + 1;
        for j=1:size(missing_frame_locations,1)
            trial_structure(3+j,i) = missing_frame_locations(j) - frame_start + 1;
        end
    else
        trial_structure(1,i) = 1 + trial_structure(2,i-1);
        trial_structure(2,i) = trial_structure(2,i-1) + trial_end - frame_start + 1;
        trial_structure(3,i) = trial_end - frame_start + 1;
        for j=1:size(missing_frame_locations,1)
            trial_structure(3+j,i) = trial_structure(1,i) + missing_frame_locations(j) - frame_start + 1;
        end
    end
    
end

% concat stim_onset and control
frames.trial_structure = trial_structure;   % save trial structure
frames.file_list = file_list;   % save order of concatenating
frames.start_frame = frame_start;     % save start frame in last row

% save file
file_nm_animal = [animal_nm file_nm];   % add animal name to file

cd ([dir_new_name]);
save(file_nm_animal,'frames');

% end


end
