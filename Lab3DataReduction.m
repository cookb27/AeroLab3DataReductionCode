clear; close all; clc;

dir_address    = pwd; % Finds Current Folder of Repo
original_files = dir([dir_address,'/*.mat']); % Searches for all files

DataArray = cell(3,size(original_files,1)); % Creates Storage Array

% Extract Calibration Coefficients
data = load(fullfile(dir_address,original_files(1).name));
DataArray{1,1} = original_files(1).name;
DataArray{2,1} = data.pDrag(1);
DataArray{3,1} = data.pDrag(2);

% For Loop To Extract All Data
for i = 2:size(original_files,1)
    data = load(fullfile(dir_address,original_files(i).name));
    DataArray{1,i} = original_files(i).name(11:size(original_files(i).name,2));
    DataArray{2,i} = mean(data.volData);
    DataArray{3,i} = std(data.volData);
end