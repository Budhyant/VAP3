% clear
% clc
warning off
PLOTON = 0;

% Import Borer L/D Data
load('borer.mat')

% Define flight speed and conditions
KTAS = [120:10:160];
vecVEHVINF = KTAS*0.514444;
rho = 1.225;
altitude = 0;
weightN = 13344.6648; % 3000 lb in N
N = 2; % number of engines 

% Load wing only VAP3 results
WING = load('VAP32_WING_VISCOUS.mat');
% Calculate CL at VINF and S&L flight
S    = WING.OUTP(1).valAREA; % ref. platform area
CL   = weightN./(0.5*rho*vecVEHVINF.^2*S);


% interpolate alpha to maintain steady level flight at VINF 
% using wing only data
seqALPHA = interp1([WING.OUTP.vecCLv],[WING.OUTP.vecVEHALPHA],CL);

% get L/D from Borer Data
LD = interp1(borer(:,1),borer(:,2),KTAS);

if PLOTON == 1
    figure(1)
    plot(borer(:,1)*0.514444,borer(:,2),'-')
    hold on
    plot(vecVEHVINF,LD,'o')
    hold off
    grid minor
    xlabel('VINF, m/s')
    ylabel('L/D')
    legend('Borer L/D Data', 'VINF Interpolation')
end

% Calculate CD with Borer L/D Data
CD = CL./(LD);
% Calulate drag force in Newton
D  = 0.5*rho*vecVEHVINF.^2.*CD*S;
% Calculate Thrust force required from EACH PROP
T  = D/N;

% Load prop only VAP3 results
PROP = load('VAP31_CRUISE_PROP_J_CT_SWEEP.mat');
ROTDIAM  = PROP.OUTP(1).vecROTDIAM(1); % should be 1.524
ROTORRPM = PROP.OUTP(1).vecROTORRPM(1); %should be 2250
rps      = ROTORRPM/60;

% Calculate CT required to maintain S&L flight
CT = T/(rho*rps^2*ROTDIAM^4);

% use scatteredInterpolant to avoid meshgrid
propVINF = [PROP.OUTP.vecVINF]';
propCT   = [PROP.OUTP.vecCT_AVG]';
propColl = [PROP.OUTP.vecCOLLECTIVE]';


% meshgrids of 3d vinf,ct,collective data
propVINF = reshape(propVINF,[],length(unique(propVINF)));
propCT   = reshape(propCT,[],length(unique(propVINF)));
propColl = reshape(propColl,[],length(unique(propVINF)));

for n = 1:size(propVINF,1)
    [~,maxCTidx] = max(propCT(:,n));
    propCT(maxCTidx+1:end,n) = nan;
end




% idx = propColl<=0; % quick way to hack off the partially stalled propeller
idx = ~isnan(propCT);

F = scatteredInterpolant(propVINF(idx), propCT(idx), propColl(idx),'linear','none');

vecCOLLECTIVE = F(vecVEHVINF, CT);


vecCOLLECTIVE = vecCOLLECTIVE(~isnan(vecCOLLECTIVE));
CT = CT(~isnan(vecCOLLECTIVE));
vecVEHVINF = vecVEHVINF(~isnan(vecCOLLECTIVE));

if PLOTON == 1
    [Xq,Yq] = meshgrid(unique(propVINF),min(propCT):0.02:max(propCT));
    Vq = F(Xq,Yq);
    
    
    figure(2)
%         scatter3(propVINF(idx),propCT(idx),propColl(idx),50,propVINF(idx),'filled')
    surf(propVINF,propCT,propColl,'FaceAlpha',.8);
    xlabel('VINF, m/s')
    ylabel('CT')
    zlabel('Collective Pitch, deg')
    hold on
    scatter3(vecVEHVINF, CT, vecCOLLECTIVE,100,'.r')
    hold off
    grid minor
end

%%
% Running
warning off
filename = 'inputs/J_COLE_BASELINE_SYM.vap';
parfor i = 1:length(vecCOLLECTIVE)
    VAP_IN = [];
    VAP_IN.vecVEHALPHA = seqALPHA(i);
    VAP_IN.vecCOLLECTIVE = vecCOLLECTIVE(i);
    VAP_IN.vecVEHVINF = vecVEHVINF(i);
    VAP_IN.valSTARTFORCES = 138;
    VAP_IN.valMAXTIME = 160;
    
    OUTP(i) = fcnVAP_MAIN(filename, VAP_IN);

    fprintf('finished AOA=%.1f\n',seqALPHA(i));
end

save('VAP32_WPforCDo_TS160_22_fixed_iter1.mat')
%%
% CD
% [OUTP.vecCD]
% CD-[OUTP.vecCD]





