% Aero Lab 3 Data Reduction
clear; close all; clc;

dir_address    = pwd; % Finds Current Folder of Repo
original_files = dir([dir_address,'/*.mat']); % Searches for all files

DataArray = cell(11,size(original_files,1)-1); % Creates Storage Array

% Extract Calibration Coefficients
data = load(fullfile(dir_address,original_files(2).name));
DataArray{1,1} = original_files(1).name;
DataArray{2,1} = data.pDrag(1);
DataArray{3,1} = data.pDrag(2);

% For Loop To Extract All Data
for i = 3:size(original_files,1)
    data = load(fullfile(dir_address,original_files(i).name));

    % Keep Name of File
    DataArray{1,i-1} = original_files(i).name(11:size(original_files(i).name,2)-4);
    % Apply Cal Curve to Mean Voltages
    DataArray{2,i-1} = DataArray{2,1}*mean(data.volData)+DataArray{3,1};
    % Apply Cal Curve to Standard Error of Voltages
    DataArray{3,i-1} = 1.96*DataArray{2,1}*std(data.volData)/size(data.volData,1);
end
clear data dir_address original_files
% All Data Are in POUNDS now

%% Hard Coding Values
rho = 1.225;
mu  = 1.81e-5;

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

DataArray(:,iVector) = []; % Remove Tare Entries from Main Data Array
clear iVector

%% Aerodynamic Tares
StingRunIndices  = find(contains(DataArray(1,:),'sting')); % Find Sting Runs
StingTareIndices = find(contains(TareArray(1,:),'sting')); % Find Sting Tares

AeroTare10       = cell(2,1);
AeroTare20       = cell(2,1);

AeroTare10{1,1}  = DataArray{2,StingRunIndices(1)} - TareArray{2,StingTareIndices(1)};
AeroTare10{2,1}  = sqrt(DataArray{3,StingRunIndices(1)}.^2 +...
                   DataArray{3,StingTareIndices(1)}.^2);
AeroTare10{2,1}  = DataArray{2,1}*AeroTare10{2,1};

AeroTare20{1,1}  = DataArray{2,StingRunIndices(2)} - TareArray{2,StingTareIndices(2)};
AeroTare20{2,1}  = sqrt(DataArray{3,StingRunIndices(2)}.^2 +...
                   DataArray{3,StingTareIndices(2)}.^2);
AeroTare20{2,1}  = DataArray{2,1}*AeroTare20{2,1};

DataArray(:,StingRunIndices)  = [];
TareArray(:,StingTareIndices) = [];

%% Iterate Over All Runs
Names = DataArray(1,2:size(DataArray,2));
for i = 1:size(Names,2)
    [drag,d_unc_1,d_unc_2] = findDrag(Names{i},DataArray,TareArray);
    
    [length,diam,area,area_unc] = AreaFinder(Names{i});

    if (~isempty(strfind(Names{i},'10'))) % 10m/s Run
        AeroTare = AeroTare10;
        q = 0.5*rho*10^2; % 10 m/s dynamic pressure (FIX ME!)
        DataArray{6,i+1} = q;
        DataArray{10,i+1} = rho*10*diam/mu;
    elseif (~isempty(strfind(Names{i},'20'))) % 20m/s Run
        AeroTare = AeroTare20;
        q = 0.5*rho*20^2; % 20 m/s dynamic pressure (FIX ME!)
        DataArray{6,i+1} = q;
        DataArray{10,i+1} = rho*20*diam/mu;
    end

    DataArray{7,i+1} = area;

    % CHECK SIGNS BEFORE MOVING FORWARDS

    drag = drag - AeroTare{1,1};

    DataArray{4,i+1} = drag;
    DataArray{5,i+1} = DataArray{2,1}*sqrt(d_unc_1^2 + d_unc_2^2);
    % DataArray{6,i+1} = d_unc_2;
    % DataArray(7,i+1) = AeroTare(2);
    DataArray{5,i+1} = sqrt(DataArray{5,i+1}^2 + AeroTare{2}^2);

    DataArray{8,i+1} = drag/(q*area);

    term1 = DataArray{5,i+1}/(q*area); % TEMP CODE!
    term2 = drag*0.05/(q*area);        % TEMP CODE! 5% uncertainty in q
    term3 = drag*area_unc/(q*area^2);  % TEMP CODE! 5% uncertainty in q

    DataArray{9,i+1} = sqrt(term1^2 + term2^2 + term3^2);

    DataArray{11,i+1} = diam/length; % Aspect Ratio
end

clear AeroTare d_unc_1 d_unc_2 drag i j StingRunIndices StingTareIndices
clear term1 term2 term3 length mu rho q area area_unc

% Data are stored per row as:
% 1  Name
% 2  Raw Pounds Read
% 3  Uncertainty Pounds Read
% 4  Drag Found
% 5  Total Uncertainty
% 6  q 
% 7  A
% 8  CD
% 9  CD_unc
% 10 Re
% 11 t/c

%% Plotting 
% Creating name vector for bar graph
Names = replace(Names,'_',' ');

X = categorical(Names); % Converts from cell to categorical
X = reordercats(X,Names); % Preserves order of cells (doesn't alphabetize)

f1 = figure;
hold on
bar(X,cell2mat(DataArray(8,2:15)));
er = errorbar(X,cell2mat(DataArray(8,2:15)),cell2mat(DataArray(9,2:15)));
er.LineStyle = 'none';
ylabel("C_D")
grid on

%% 
f2  = figure;
ax2 = axes;

load CdvsReData

% NOTE: Cite this code as being from canvas
plot(CdvsReSphere(:,1),CdvsReSphere(:,2),'-r',...
    CdvsReDisk(:,1),CdvsReDisk(:,2),'-b',...
    CdvsReHull(:,1),CdvsReHull(:,2),'-k',...
    CdvsReEllipsoid(:,1),CdvsReEllipsoid(:,2),'-m',...
    'LineWidth',2)
hold on
scatter(ax2,cell2mat(DataArray(10,2:15)),cell2mat(DataArray(8,2:15)));
grid on
xlim([0.1 1e7])
ylim([0.01 100])
set(gca,'XScale','log','YScale','log')
xlabel('$Re$','Interpreter','latex','FontSize',16)
ylabel('$C_D$','Interpreter','latex','FontSize',16)
legend('Smooth sphere','Disk','Airship hull','2:1 Ellipsoid',...
    'Found Drag Coefficients',...
    'Location','NorthOutside','Numcolumns',2,'FontSize',16,...
    'Interpreter','latex')
axis([1e4 1e6 1e-2 2e0])
T = text(cell2mat(DataArray(10,2:15)),cell2mat(DataArray(8,2:15)),Names);

for i = 1:size(T,1)
    if (contains(Names(i),'10'))
        LR = 'right';
        VERT = 'bottom';
    elseif (contains(Names(i),'20'))
        LR = 'left';
        VERT = 'middle';
    end

    if (contains(Names(i),'golf') || contains(Names(i),'convex'))
        LR = 'right';
    elseif (contains(Names(i),'hollow') || contains(Names(i),'convex'))
        VERT = 'bottom';
    elseif (contains(Names(i),'solid'))
        VERT = 'top';
    end

    T(i,1).HorizontalAlignment = LR;
    T(i,1).VerticalAlignment   = VERT;
end

%% Drag Compared By Aspect Ratio
figure
hold on
scatter(cell2mat(DataArray(11,2:15)),cell2mat(DataArray(8,2:15)));
xlabel("Aspect Ratio")
ylabel("C_D")
grid on
title("Found Drag Coefficients Over Aspect Ratios")
T2 = text(cell2mat(DataArray(11,2:15)),cell2mat(DataArray(8,2:15)),Names);

for i = 1:size(T,1)
    if (DataArray{11,i+1}==1) % || contains(Names(i),"ball") || contains(Names(i),"sphere")  
        LR   = 'right';
        VERT = 'bottom';
    else
        LR   = 'left';
        VERT = 'bottom';
    end

    T2(i,1).HorizontalAlignment = LR;
    T2(i,1).VerticalAlignment   = VERT;
end

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

% This function finds the area based on name alone
function [length, diam, area, area_unc] = AreaFinder(name)
    % Hard coding in lengths (inches, to be converted)
    Diams   = [2.95  % Diam   Disk
               3.03  % Diam   Concave
               3.08  % Diam   Convex
               2.99  % Diam   Smooth
               3.03  % Diam   Rough
               1.58  % Diam   Ping-Pong
               1.67  % Diam   Golfball
               3.41  % Diam Solid Nerf
               3.46  % Diam Hollow Nerf
               1.38]; % Diam Putty
    
    Lengths = [2.95  % Diam   Disk
               3.03  % Diam   Concave
               3.08  % Diam   Convex
               2.99  % Diam   Smooth
               3.03  % Diam   Rough
               1.58  % Diam   Ping-Pong
               1.67  % Diam   Golfball
               11.1  % Length Solid Nerf
               6.38  % Length Hollow Nerf
               4.25]; % Length Putty

    Lengths  = Lengths/39.37;
    Diams    = Diams/39.37;
    area_unc = (pi/2).*Diams.*0.001;

    if (contains(name,'disk'))
        diam     = Diams(1);
        length   = Lengths(1);
        area     = pi/4 * diam^2;
        area_unc = area_unc(1);
    elseif (contains(name,'concave'))
        diam     = Diams(2);
        length   = Lengths(2);
        area     = pi/4 * diam^2;
        area_unc = area_unc(2);
    elseif (contains(name,'convex'))
        diam     = Diams(3);
        length   = Lengths(3);
        area     = pi/4 * diam^2;
        area_unc = area_unc(3);
    elseif (contains(name,'smooth'))
        diam     = Diams(4);
        length   = Lengths(4);
        area     = pi/4 * diam^2;
        area_unc = area_unc(4);
    elseif (contains(name,'rough'))
        diam     = Diams(5);
        length   = Lengths(5);
        area     = pi/4 * diam^2;
        area_unc = area_unc(5);
    elseif (contains(name,'ping'))
        diam     = Diams(6);
        length   = Lengths(6);
        area     = pi/4 * diam^2;
        area_unc = area_unc(6);
    elseif (contains(name,'golf'))
        diam     = Diams(7);
        length   = Lengths(7);
        area     = pi/4 * diam^2;
        area_unc = area_unc(7);
    elseif (contains(name,'solid'))
        diam     = Diams(8);
        length   = Lengths(8);
        area     = pi/4 * diam^2;  % FIX ME - Area is INCORRECT
        area_unc = area_unc(8);      % FIX ME - Area unc is INCORRECT
    elseif (contains(name,'hollow'))
        diam     = Diams(9);
        length   = Lengths(9);
        area     = pi/4 * diam^2;  % FIX ME - Area is INCORRECT
        area_unc = area_unc(9);      % FIX ME - Area unc is INCORRECT
    elseif (contains(name,'putty'))
        diam     = Diams(10);
        length   = Lengths(10);
        area     = pi/4 * diam^2; % FIX ME - Area is INCORRECT
        area_unc = area_unc(10);     % FIX ME - Area unc is INCORRECT
    else
        fprintf("\nArea not found\n");
        fprintf("Input was %s",name);
        area     = NaN; 
        area_unc = NaN;
        length   = NaN;
    end
end