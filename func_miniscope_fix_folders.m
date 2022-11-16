%% script to complete directory names to get 11 values

% put all Miniscope sub directories in one main directory
% e.g. main: animal1, sub: H12_M44_S30, H12_M44_S58, H12_M45_S22
% these sub's contain the recordings (e.g. msCam1, msCam2) and
% timestamp.dat files

% script first asks for how many main directories you want to load
% script then asks you to select every directory you want to load one by one
% it makes sure all directories have 11 characters to index in Matlab
% e.g. H10_M5_S9 will become H10_M05_S09, etc
% it does not add anything to directory names with 11 values

function func_miniscope_fix_folders(animal_dir)

% retrieve the name of the directories only
names = dir;
names(ismember( {names.name}, {'.', '..'})) = []; % delete . and ..
names = {names([names.isdir]).name};
index = find(startsWith(names, 'H')); % find directories starting with H
names = names(index);

% calculate the length of each name and exclude names of 11 long
len  = cellfun('length',names);
idx   = len < 11;
names = names(idx);

% Rename in a LOOP
for i = 1:numel(names)
    
    % cut name
    oldname = cell2mat(names(i));
    oldname_split = strsplit(oldname,'_');
    
    for j=1:numel(oldname_split)
        if strlength(oldname_split(j)) == 3
        else
            name_pre = extractBefore(oldname_split(j),2);
            name_post = extractAfter(oldname_split(j),1);
            new = strcat(name_pre, '0', name_post);
            old = string(oldname_split(j));
            oldname_split(j) = replace(oldname_split(j),old,new);
        end
    end
    
    newname = strjoin(oldname_split,{'_'});
    dos(['rename "' oldname '" "' newname '"']); % (1)
end

end
