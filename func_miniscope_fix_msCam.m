%% script to add zeros (0) to msCam files to maintain same length

% it adds a '0' to msCam1 till msCam9 before the number:
% msCam1 becomes msCam01, etc
% it does not add anything to file names with 2 number or more

function func_miniscope_fix_msCam(animal_dir)

% check how many folders
rec_dir = dir;
rec_dir(ismember( {rec_dir.name}, {'.', '..'})) = []; % delete . and ..
rec_dir = {rec_dir([rec_dir.isdir]).name};
index = find(startsWith(rec_dir, 'H')); % find directories starting with H
rec_dir = rec_dir(index);

for kk=1:size(rec_dir,2)
    
    cd([rec_dir{kk}])
    % retrieve the name of the .avi files only
    names = dir;
    names = {names(~[names.isdir]).name};
    index = find(contains(names, '.avi'));
    names = names(index);
    % calculate the length of each name and the max length
    len  = cellfun('length',names);
    mLen = max(len);
    % exclude from renaming the files long as the max
    idx   = len < mLen;
    % len   = len(idx);
    names = names(idx);
    
    % rename in a loop
    for n = 1:numel(names)
        
        % cut name
        oldname = cell2mat(names(n));
        name_pre = oldname(1:5);
        name_post = oldname(6:end);
        newname = [name_pre '0' name_post];
        
        dos(['rename "' oldname '" "' newname '"']); % (1)
    end
    
    cd ..
end

end
