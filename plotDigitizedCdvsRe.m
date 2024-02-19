clc; clear all; close all;

load CdvsReData

figure
plot(CdvsReSphere(:,1),CdvsReSphere(:,2),'-r',...
    CdvsReDisk(:,1),CdvsReDisk(:,2),'-b',...
    CdvsReHull(:,1),CdvsReHull(:,2),'-k',...
    CdvsReEllipsoid(:,1),CdvsReEllipsoid(:,2),'-m',...
    'LineWidth',2)
grid
xlim([0.1 1e7])
ylim([0.01 100])
set(gca,'XScale','log','YScale','log')
xlabel('$Re$','Interpreter','latex','FontSize',16)
ylabel('$C_D$','Interpreter','latex','FontSize',16)
legend('Smooth sphere','Disk','Airship hull','2:1 Ellipsoid',...
    'Location','NorthOutside','Numcolumns',2,'FontSize',16,...
    'Interpreter','latex')

    