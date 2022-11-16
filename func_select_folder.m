%% Function to select folders - either manually one by one, or matlab selects all animal experimental folders at once

% function asks if you want to select experiments manually or automatically
% folder structure: main folder - animal - experiment
% manually you select 'animal', automatically you select 'main folder'

function [main_dir folder_extension] = select_folder()

% do you wanna select animals yourself or all animals in a given folder?
select_option = input('Do you wanna select animals yourself or all animals in a given folder (0:self 1:all):');


% select folders
if select_option == 0
    
    % ask user how many folders to read to run sequentially
    num_dir = input('How many animals do you want to put in a struct: ');
    
    % ask for folder extension
    folder_extension = input('What is the extension of the session folder you wanna analyze: ','s');
    folder_extension = ['*' folder_extension];
    
    % ask user to select main directories
    %     dialog_title = 'Select the main animal directory with the folder behavior and imaging in it';
    dialog_title = 'Select the main animal directory (matlab will find experimental folders)';
    for i = 1 : num_dir
        main_dir{i,:} = uigetdir('',dialog_title)
        if main_dir{i,:} == 0;  % if you press cancel, script should stop
            return
        end
    end
    
    % find folders that end with variable you are interested in
    for k=1:size(main_dir,1)
        clear folder_nm
        cd(main_dir{k})
        folder_nm = dir(folder_extension);
        main_dir{k,2} = ['\' folder_nm.name];
        if isempty(main_dir{k,2})
            disp('Could not find your experimental folder!')
            fprintf('Check folder: %s \n', main_dir{k})
            return      % stop scripts
        end
    end
    
elseif select_option == 1       % matlab finds all folders
    
    % ask for folder extension
    folder_extension = input('What is the extension of the session folder you wanna analyze: ','s');
    folder_extension = ['*' folder_extension];
    
    % ask user to select main directories
    dialog_title = 'Select the main directory (matlab will find animals and experimental folders)';
    main_top_dir = uigetdir('',dialog_title)
    
    % go to folder
    cd(main_top_dir)
    % find all folders
    all_files = dir;
    % remove . and ..
    all_files(ismember( {all_files.name}, {'.', '..'})) = [];
    % get a logical vector that tells which is a directory.
    dir_flags = [all_files.isdir];
    % extract only those that are directories.
    sub_folders = all_files(dir_flags);
    
    % check if experimental folder is there
    for k=1:size(sub_folders,1)
        clear folder_nm
        cd(sub_folders(k).name)
        folder_nm = dir(folder_extension);
        main_dir{k,1} = [main_top_dir '\' sub_folders(k).name];
        
        if isempty(folder_nm)
            fprintf('Could not find your experimental folder %s in: %s \n',folder_extension,sub_folders(k).name)
            disp('Let us check the next animal')
        else
            main_dir{k,2} = ['\' folder_nm.name];
        end
        cd ..
    end
    
    % check if we have folders with no experiment
    empty_flags = [];
    for k=1:size(sub_folders,1)
        if isempty(main_dir{k,2})
            empty_flags = [empty_flags k];
        end
    end
    
    % delete empty rows
    c=0;
    for k=1:size(empty_flags,2)
        main_dir(empty_flags(k)-c,:) = [];
        c=c+1;
    end
    
else
    disp('Error: unclear how you want to select experiments')
end

for k=1:size(main_dir,1)
    main_dir{k,1} = [main_dir{k,1} main_dir{k,2}];
end

end
