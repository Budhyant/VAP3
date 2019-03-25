function [out, dataout] = fcnBASELINE(home_dir)
cd(home_dir)

if exist('aux_files','file') ~= 7
    mkdir('aux_files');
end

% relax, start force, aux_files

%
%% Setting up files
vap_filename = ['aux_files/', regexprep(tempname('/'), {'/', '\'}, ''), '.vap'];
copyfile('Standard_Cirrus.vap', vap_filename);

geom = [0 0 0 0.92 0; 0.179 4.464 0.234 0.675 0.3; 0.30 7.5 0.3874 0.375 1.8];

pan(1).geom = geom;

vap3_inputmod_wing(vap_filename, pan)

cd ./../../
seqALPHA = [2:1:8];
% seqALPHA = [2:0.25:8];
for i = 1:length(seqALPHA)
    VAP_IN = [];
    VAP_IN.RELAX = 0;
    VAP_IN.valSTARTFORCES = 40;
    VAP_IN.vecVEHALPHA = seqALPHA(i);
    WING_SWEEP(i) = fcnVAP_MAIN(['Runs/Winglet Optimization/', vap_filename], VAP_IN);
end
cd('Runs/Winglet Optimization/');
delete(vap_filename)

dataout.WING_SWEEP = WING_SWEEP;

% gca;
% xlim([0 1]-(40*0.25))
% ylim([7.50-0.7 7.6])
% zlim([-0.1 0.9])
% view([-48 11])

%% Analysis
% Calculate CL at VINF and S&L flight
valAREA    = WING_SWEEP(1).valAREA; % ref. platform area
valDENSITY    = WING_SWEEP(1).valDENSITY;
valWEIGHT = WING_SWEEP(1).vecVEHWEIGHT;
vecCLv   = [WING_SWEEP.vecCLv_AVG]';
vecCD = [WING_SWEEP.vecCD_AVG]';
vecVINF = [WING_SWEEP.vecVINF]';
vecVINF = vecVINF(:,end);
vecCDi = [WING_SWEEP.vecCDI_AVG]';

%% Cross-country speed
[LDfit, ~] = fcnCREATEFIT(seqALPHA, vecCLv./vecCD);
[CLfit, ~] = fcnCREATEFIT(seqALPHA, vecCLv);
[CDfit, ~] = fcnCREATEFIT(seqALPHA, vecCD);
[Vinffit, ~] = fcnCREATEFIT(seqALPHA, vecVINF);
[Cdifit, ~] = fcnCREATEFIT(seqALPHA, vecCDi);

range_vxc = 2:0.25:max(seqALPHA);
CL = CLfit(range_vxc);
CD = CDfit(range_vxc);
LD = LDfit(range_vxc);
Vcruise = Vinffit(range_vxc);
wglide = Vcruise.*(CD./CL);
[~, LDindex] = max(LD);

dataout.range_vxc = range_vxc;
dataout.CL = CL;
dataout.CD = CD;
dataout.LD = LD;
dataout.Vcruise = Vcruise;
dataout.wglide = wglide;

dataout.LDfit = LDfit;
dataout.CLfit = CLfit;
dataout.CDfit = CDfit;
dataout.Vinffit = Vinffit;
dataout.Cdifit = Cdifit;


% % Check
% hFig10 = figure(10);
% clf(10);
% subplot(2,2,1)
% hold on
% scatter(seqALPHA, vecCLv, 'ok');
% plot(range_vxc, CL, '-k');
% hold off
%
% subplot(2,2,2)
% hold on
% scatter(vecCD, vecCLv, 'ok');
% plot(CD, CL, '-k');
% hold off
%
% subplot(2,2,3)
% hold on
% scatter(seqALPHA, vecVINF, 'ok');
% plot(range_vxc, Vcruise, '-k');
% hold off
%
% subplot(2,2,4)
% hold on
% scatter(seqALPHA, vecCLv./vecCD, 'ok');
% plot(range_vxc, LD, '-k');
% hold off

Rthermal = 150;
Rrecip = 1/Rthermal;
WSroh = 2*valWEIGHT/(valAREA*valDENSITY);

k = 1;

for wmaxth = 2:0.25:8
% for wmaxth = 2:3:8
    j = 1;
    
    for i = LDindex:size(CL)
        wclimb(j,1) = fcnMAXCLIMB(CL(i), CD(i), Rrecip, wmaxth, WSroh);
        j = j + 1;
    end
    
    [wclimbMAX, indexWC] = max(wclimb);
    
    for i = 1:size(CL)
        V(i,1) = (Vcruise(i)*wclimbMAX)/(wglide(i)+wclimbMAX);
    end
    
    [VxcMAX, cruiseIndex] = max(V);
    invVxcMAX(k,1) = 1/VxcMAX;
    Vxc(k,:) = [wmaxth VxcMAX];
    k = k + 1;
    
end

dataout.Vxc = Vxc;
invVxcMAX_low = invVxcMAX(1,1);
invVxcMAX_med = invVxcMAX(ceil(end/2),1);
invVxcMAX_high = invVxcMAX(end,1);

%% High speed CD
highspeed_cd = interp1(vecVINF, vecCD, 51, 'linear', 'extrap');
dataout.highspeed_cd = highspeed_cd;

%% Wing root bending moment
idx = 2;
root_bending = sum(WING_SWEEP(idx).WING.vecLDIST(end,:)'.*WING_SWEEP(idx).WING.vecSPANLOC_PROJ);
dataout.root_bending = root_bending;

%% Output
out = [invVxcMAX_low invVxcMAX_med invVxcMAX_high root_bending highspeed_cd];

end
