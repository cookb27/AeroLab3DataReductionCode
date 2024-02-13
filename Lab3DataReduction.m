clear; close all; clc;

dir_address    = pwd; % Finds Current Folder of Repo
original_files = dir([dir_address,'/*.mat']); % Searches for all files

DataArray = cell(6,size(original_files,1)); % Creates Storage Array

% Extract Calibration Coefficients
data = load(fullfile(dir_address,original_files(1).name));
DataArray{1,1} = original_files(1).name;
DataArray{2,1} = data.pDrag(1);
DataArray{3,1} = data.pDrag(2);

% For Loop To Extract All Data
for i = 2:size(original_files,1)
    data = load(fullfile(dir_address,original_files(i).name));

    % Keep Name of File
    DataArray{1,i} = original_files(i).name(11:size(original_files(i).name,2)-4);
    % Apply Cal Curve to Mean Voltages
    DataArray{2,i} = DataArray{2,1}*mean(data.volData)+DataArray{3,1};
    % Apply Cal Curve to Standard Error of Voltages
    DataArray{3,i} = 1.96*DataArray{2,1}*std(data.volData)/size(data.volData,2);
end
clear data dir_address original_files
% All Data Are in POUNDS now

%% Assemble the Tares In One Array
TareArray = cell(3,16); % Cell Array for Tares
j         = 0; % Counter
iVector   = []; % Vector of Tare Indices
for i = 1:size(DataArray,2)
    if (~isempty(strfind(DataArray{1,i},'tare')))
        j = j + 1;
        TareArray(:,j) = DataArray(1:3,i);
        iVector = [iVector,i];
    end
end

DataArray(:,iVector) = []; % Remoce Tare Entries from Main Data Array
clear iVector

%% Aerodynamic Tares
StingRunIndices  = find(contains(DataArray(1,:),'sting')); % Find Sting Runs
StingTareIndices = find(contains(TareArray(1,:),'sting')); % Find Sting Tares

AeroTare10       = DataArray{2,StingRunIndices(1)} - TareArray{2,StingTareIndices(1)};
AeroTare20       = DataArray{2,StingRunIndices(2)} - TareArray{2,StingTareIndices(2)};

% NEED TO ADD IN UNCERTAINTY HERE BEFORE CLEARING DATA

DataArray(:,StingRunIndices)  = [];
TareArray(:,StingTareIndices) = [];

%% Iterate Over All Runs
Names = DataArray(1,2:size(DataArray,2));
for i = 1:size(Names,2)
    [drag,d_unc_1,d_unc_2] = findDrag(Names{i},DataArray,TareArray);
    
    if (~isempty(strfind(Names{i},'20'))) % 10m/s Run
        AeroTare = AeroTare10;
    elseif (~isempty(strfind(Names{i},'10'))) % 20m/s Run
        AeroTare = AeroTare20;
    end

    drag = drag - AeroTare;

    DataArray{4,i+1} = drag;
    DataArray{5,i+1} = d_unc_1;
    DataArray{6,i+1} = d_unc_2;
    % DataArray{7:8,i+1} = AeroTare{2:3};
end

% Data are stored per column as:
% Name
% Raw Pounds Read
% Uncertainty Pounds Read
% Drag Found
% Uncertainty in Raw Pounds Reading
% Uncertainty in Tare Pounds Reading
% TO BE IMPLEMENTED Uncertainty in Raw Aero Pounds Reading
% TO BE IMPLEMENTED Uncertainty in Sting Tare Pound Reading

%% Functions
% This function will find the find and remove the tare data
function [Drag,Drag_unc1,Drag_unc2] = findDrag(name,Data,Tare)
    for i = 1:size(Data,2)
        if (~isempty(strfind(Data{1,i},name)))
            for j = 1:size(Tare,2)
                 if (~isempty(strfind(Tare{1,j},name)))
                     Drag      = Data{2,i} - Tare{2,j};
                     Drag_unc1 = Data{3,i}; % Std Error of Run
                     Drag_unc2 = Tare{3,j}; % Std Error of Tare
                 end
            end
        end
    end
end