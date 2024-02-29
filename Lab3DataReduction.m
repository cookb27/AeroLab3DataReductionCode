% Aero Lab 3 Data Reduction
clear; close all; clc;

dir_address    = pwd; % Finds Current Folder of Repo
original_files = dir([dir_address,'/*.mat']); % Searches for all files

DataArray = cell(12,size(original_files,1)-1); % Creates Storage Array

% Note: Skipping file #1, that's for the Cd vs Re plot

% Extract Calibration Coefficients
data = load(fullfile(dir_address,original_files(2).name));
DataArray{1,1} = original_files(2).name;
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
    DataArray{3,i-1} = 1.96*DataArray{2,1}*std(data.volData)/sqrt(size(data.volData,1));
end
clear data dir_address original_files
% All Data Are in Newtons now

%% Hard Coding Values
mu        = 1.81e-5;
inH20ToPa = 249.08; % Pa / inH20
T0        = 295.9; % K
P0        = 101422; % Pa
R         = 287; 
rho       = P0/(R*T0);
rho_unc   = 1/R * sqrt((16.9/T0)^2 + (P0*0.278/T0^2)^2);

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

AeroTare20{1,1}  = DataArray{2,StingRunIndices(2)} - TareArray{2,StingTareIndices(2)};
AeroTare20{2,1}  = sqrt(DataArray{3,StingRunIndices(2)}.^2 +...
                   DataArray{3,StingTareIndices(2)}.^2);

DataArray(:,StingRunIndices)  = [];
TareArray(:,StingTareIndices) = [];

%% Iterate Over All Runs
Names = DataArray(1,2:size(DataArray,2));
for i = 1:size(Names,2)
    [drag,d_unc_1,d_unc_2] = findDrag(Names{i},DataArray,TareArray);
    
    [length,diam,area,area_unc] = AreaFinder(Names{i});

    if (~isempty(strfind(Names{i},'10'))) % 10m/s Run
        AeroTare = AeroTare10;
        q        = 0.24*inH20ToPa; % 10 m/s dynamic pressure target
        v        = sqrt(2*q/rho);
        v_unc    = 1.435;

        term1    = v*length*rho_unc;
        term2    = rho*length*v_unc;
        term3    = rho*v*0.005/39.97;

        Re       = rho*v*length/mu;
        Re_unc   = 1/mu * sqrt(term1^2 + term2^2 + term3^2);
        
        clear term1 term2 term3
    elseif (~isempty(strfind(Names{i},'20'))) % 20m/s Run
        AeroTare = AeroTare20;
        q        = 0.95*inH20ToPa; % 20 m/s dynamic pressure target
        v        = sqrt(2*q/rho);
        v_unc    = 1.456;

        term1    = v*length*rho_unc;
        term2    = rho*length*v_unc;
        term3    = rho*v*0.005/39.97;

        Re       = rho*v*length/mu;
        Re_unc   = 1/mu * sqrt(term1^2 + term2^2 + term3^2);

        clear term1 term2 term3
    end

    drag     = drag - AeroTare{1,1};
    drag_unc = sqrt(d_unc_1^2 + d_unc_2^2 + AeroTare{2}^2);
    q_unc    = 0.005*inH20ToPa;

    term1    = drag_unc/(q*area);
    term2    = (drag*q_unc)/(q^2*area);
    term3    = drag*area_unc/(q*area^2);

    CD_unc   = sqrt(term1^2 + term2^2 + term3^2);

    clear term1 term2 term3

    AR_unc = sqrt(((0.005/39.97)/length)^2+...
                  ((0.005/39.97)*diam/length^2)^2);
     
    DataArray{4,i+1}  = drag;
    DataArray{5,i+1}  = drag_unc;
    DataArray{6,i+1}  = q;
    DataArray{7,i+1}  = area;
    DataArray{8,i+1}  = drag/(q*area);
    DataArray{9,i+1}  = CD_unc;
    DataArray{10,i+1} = Re;
    DataArray{11,i+1} = diam/length; % Aspect Ratio
    DataArray{12,i+1} = Re_unc;
    DataArray{13,i+1} = AR_unc;
    DataArray{14,i+1} = area_unc;
end

clear AeroTare d_unc_1 d_unc_2 drag i j StingRunIndices StingTareIndices
clear term1 term2 term3 length q area area_unc

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
% 12 Re_unc ! REORDER !
% 13 AR_unc
% 14 A_unc

%% Overall Drag of All Items 
% Creating name vector for bar graph
Names = replace(Names,'_',' ');

X = categorical(Names); % Converts from cell to categorical
X = reordercats(X,Names); % Preserves order of cells (doesn't alphabetize)

f1  = figure;
ax1 = axes;
hold on

bar(X,cell2mat(DataArray(4,2:15)));
er = errorbar(X,cell2mat(DataArray(4,2:15)),...
    cell2mat(DataArray(5,2:15)));

er.LineStyle = 'none';
ylabel("Drag (N)");
title("Total Drag Force on All Shapes");
grid on

ax1.FontSize = 20; 

%% Drag Coefficient Over Reynolds Numbers
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
er1 = errorbar(ax2,cell2mat(DataArray(10,2:15)),cell2mat(DataArray(8,2:15)),...
    cell2mat(DataArray(9,2:15)),cell2mat(DataArray(9,2:15)),...
    cell2mat(DataArray(12,2:15)),cell2mat(DataArray(12,2:15)));
er1.LineStyle = 'none';
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

%% Drag Coefficients Compared By Aspect Ratio
f3  = figure;
ax3 = axes;
hold on
scatter(cell2mat(DataArray(11,2:15)),cell2mat(DataArray(8,2:15)));

er2 = errorbar(cell2mat(DataArray(11,2:15)),cell2mat(DataArray(8,2:15)),...
    cell2mat(DataArray(9,2:15)),cell2mat(DataArray(9,2:15)),...
    cell2mat(DataArray(13,2:15)),cell2mat(DataArray(13,2:15)));

er2.LineStyle = 'none';

xlabel("Aspect Ratio")
ylabel("C_D")
grid on
title("Found Drag Coefficients Over Aspect Ratios")
T2 = text(cell2mat(DataArray(11,2:15)),cell2mat(DataArray(8,2:15)),Names);

for i = 1:size(T,1)
    if (DataArray{11,i+1}==1)  
        LR   = 'right';
        VERT = 'bottom';
    else
        LR   = 'left';
        VERT = 'bottom';
    end

    T2(i,1).HorizontalAlignment = LR;
    T2(i,1).VerticalAlignment   = VERT;
end

AR1Array = DataArray;

for i = 1:size(DataArray,2)
    if AR1Array{11,i} ~= 1
        AR1Array(:,i) = num2cell(NaN(14,1));
    end
end

idx = find(isnan(cell2mat(AR1Array(2,:))));

AR1Array(:,[1,idx]) = [];

[~,I] = sort(cell2mat(AR1Array(8,:)));
AR1Array = AR1Array(:,I);

ax4 = axes('Position',[0.6 0.25 0.25 0.25]);
hold on
bar(categorical(cellstr(AR1Array(1,:))),cell2mat(AR1Array(8,:)));
er2 = errorbar(categorical(cellstr(AR1Array(1,:))),cell2mat(AR1Array(8,:)),...
    cell2mat(AR1Array(9,:)));
er2.LineStyle = 'none';
grid on
title("CD for AR = 1");
ylabel("C_D");

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
    Diams   = [2.95   % Diam   Disk
               3.03   % Diam   Concave
               3.08   % Diam   Convex
               2.99   % Diam   Smooth
               3.03   % Diam   Rough
               1.58   % Diam   Ping-Pong
               1.67   % Diam   Golfball
               3.41   % Diam Solid Nerf
               3.46   % Diam Hollow Nerf
               1.38]; % Diam Putty
    
    Lengths = [0.38    % Diam   Disk
               3.03/2  % Diam   Concave
               3.08/2  % Diam   Convex
               2.99    % Diam   Smooth
               3.03    % Diam   Rough
               1.58    % Diam   Ping-Pong
               1.67    % Diam   Golfball
               11.1    % Length Solid Nerf
               6.38    % Length Hollow Nerf
               4.25];  % Length Putty

    Lengths  = Lengths/39.37;
    Diams    = Diams/39.37;
    area_unc = (pi/2).*Diams.*0.001/39.37;

    if (contains(name,'disk'))
        index = 1;
    elseif (contains(name,'concave'))
        index = 2;
    elseif (contains(name,'convex'))
        index = 3;
    elseif (contains(name,'smooth'))
        index = 4;
    elseif (contains(name,'rough'))
        index = 5;
    elseif (contains(name,'ping'))
        index = 6;
    elseif (contains(name,'golf'))
        index = 7;
    elseif (contains(name,'solid'))
        index = 8;
    elseif (contains(name,'hollow'))
        index = 9;
    elseif (contains(name,'putty'))
        index = 10;
    else
        index = NaN;
    end

    if (isnan(index))
        fprintf("\nArea not found\n");
        fprintf("Input was %s",name);
        area     = NaN; 
        area_unc = NaN;
        length   = NaN;
    elseif index == 10
        k        = 1;
        diam     = Diams(index);
        length   = Lengths(index); 
        area     = k*diam^2;
        area_unc = 2*k*diam*0.001/39.97;     
        % area_unc = 0;
    else
        diam     = Diams(index);
        length   = Lengths(index); 
        area     = pi/4 * diam^2;
        area_unc = area_unc(index);
    end
end