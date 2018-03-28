function OUTP = fcnVAP_MAIN(filename, alpha, collective)

if nargin == 0
    VAP_MAIN;
    return
end

%% Reading in geometry
[FLAG, COND, VISC, INPU, VEHI] = fcnXMLREAD(filename);

COND.vecCOLLECTIVE = collective;
COND.vecVEHALPHA = alpha;


COND.vecWINGTRI(~isnan(COND.vecWINGTRI)) = nan;
COND.vecWAKETRI(~isnan(COND.vecWAKETRI)) = nan;
FLAG.TRI = 0;
FLAG.GPU = 0;

FLAG.PRINT = 1;
FLAG.PLOT = 0;
FLAG.VISCOUS = 1;
FLAG.CIRCPLOT = 0;
FLAG.GIF = 0;
FLAG.PREVIEW = 0;
FLAG.PLOTWAKEVEL = 0;
FLAG.PLOTUINF = 0;
FLAG.VERBOSE = 0;

% Initializing parameters to null/zero/nan
[WAKE, OUTP, INPU] = fcnINITIALIZE(COND, INPU);

if FLAG.PRINT == 1
    disp('============================================================================');
    disp('                  /$$    /$$  /$$$$$$  /$$$$$$$         /$$$$$$      /$$');
    disp('+---------------+| $$   | $$ /$$__  $$| $$__  $$       /$$__  $$    /$$$$');
    disp('| RYERSON       || $$   | $$| $$  \ $$| $$  \ $$      |__/  \ $$   |_  $$');
    disp('| APPLIED       ||  $$ / $$/| $$$$$$$$| $$$$$$$/         /$$$$$/     | $$');
    disp('| AERODYNAMICS  | \  $$ $$/ | $$__  $$| $$____/         |___  $$     | $$');
    disp('| LABORATORY OF |  \  $$$/  | $$  | $$| $$             /$$  \ $$     | $$');
    disp('| FLIGHT        |   \  $/   | $$  | $$| $$            |  $$$$$$//$$ /$$$$$$');
    disp('+---------------+    \_/    |__/  |__/|__/             \______/|__/|______/');
    disp('============================================================================');
    disp(' ');
end

% Check if the files required by the viscous calculations exist
[FLAG] = fcnVISCOUSFILECHECK(FLAG, VISC);

%% Discretizing geometry into DVEs
% Adding collective pitch to the propeller/rotor
if ~isempty(COND.vecCOLLECTIVE)
    INPU.matGEOM(:,5,INPU.vecPANELROTOR > 0) = INPU.matGEOM(:,5,INPU.vecPANELROTOR > 0) + repmat(reshape(COND.vecCOLLECTIVE(INPU.vecPANELROTOR(INPU.vecPANELROTOR > 0), 1),1,1,[]),2,1,1);
end
[INPU, COND, MISC, VISC, WAKE, VEHI, SURF] = fcnGEOM2DVE(INPU, COND, VISC, VEHI, WAKE);

%% Advance Ratio
MISC.vecROTORJ = [];
for jj = 1:length(COND.vecROTORRPM)
    MISC.vecROTORJ(jj) = (COND.vecVEHVINF(VEHI.vecROTORVEH(jj))*60)./(abs(COND.vecROTORRPM(jj)).*INPU.vecROTDIAM(jj));
end

%% Add boundary conditions to D-Matrix
[matD] = fcnDWING(SURF, INPU);

%% Add kinematic conditions to D-Matrix
[SURF.vecK] = fcnSINGFCT(SURF.valNELE, SURF.vecDVESURFACE, SURF.vecDVETIP, SURF.vecDVEHVSPN);
[matD] = fcnKINCON(matD, SURF, INPU, FLAG);

%% Preparing to timestep
% Building wing resultant
[vecR] = fcnRWING(0, SURF, WAKE, FLAG);

% Solving for wing coefficients
[SURF.matCOEFF] = fcnSOLVED(matD, vecR, SURF.valNELE);

%% Timestepping
for valTIMESTEP = 1:COND.valMAXTIME
    %% Timestep to solution
    %   Move wing
    %   Generate new wake elements
    %   Create and solve WD-Matrix for new elements
    %   Solve wing D-Matrix with wake-induced velocities
    %   Solve entire WD-Matrix
    %   Relaxation procedure (Relax, create W-Matrix and W-Resultant, solve W-Matrix)
    %   Calculate surface normal forces
    %   Calculate DVE normal forces
    %   Calculate induced drag
    %   Calculate cn, cl, cy, cdi
    %   Calculate viscous effects
    
    %% Moving the vehicles
    [SURF, INPU, MISC, VISC] = fcnMOVESURFACE(INPU, VEHI, MISC, COND, SURF, VISC);
    
    %% Generating new wake elements
    [INPU, COND, MISC, VISC, WAKE, VEHI, SURF] = fcnCREATEWAKEROW(FLAG, INPU, COND, MISC, VISC, WAKE, VEHI, SURF);
    
    if FLAG.PREVIEW ~= 1
        %% Creating and solving WD-Matrix for latest row of wake elements
        % We need to grab from WAKE.matWADJE only the values we need for this latest row of wake DVEs
        idx = sparse(sum(ismember(WAKE.matWADJE,[((WAKE.valWNELE - WAKE.valWSIZE) + 1):WAKE.valWNELE]'),2)>0 & (WAKE.matWADJE(:,2) == 4 | WAKE.matWADJE(:,2) == 2));
        temp_WADJE = [WAKE.matWADJE(idx,1) - (valTIMESTEP-1)*WAKE.valWSIZE WAKE.matWADJE(idx,2) WAKE.matWADJE(idx,3) - (valTIMESTEP-1)*WAKE.valWSIZE];
        
        [matWD, WAKE.vecWR] = fcnWDWAKE([1:WAKE.valWSIZE]', temp_WADJE, WAKE.vecWDVEHVSPN(end-WAKE.valWSIZE+1:end), WAKE.vecWDVESYM(end-WAKE.valWSIZE+1:end), WAKE.vecWDVETIP(end-WAKE.valWSIZE+1:end), WAKE.vecWKGAM(end-WAKE.valWSIZE+1:end), INPU.vecN);
        [WAKE.matWCOEFF(end-WAKE.valWSIZE+1:end,:)] = fcnSOLVEWD(matWD, WAKE.vecWR, WAKE.valWSIZE, WAKE.vecWKGAM(end-WAKE.valWSIZE+1:end), WAKE.vecWDVEHVSPN(end-WAKE.valWSIZE+1:end));
        
        %% Rebuilding and solving wing resultant
        [vecR] = fcnRWING(valTIMESTEP, SURF, WAKE, FLAG);
        
        [SURF.matCOEFF] = fcnSOLVED(matD, vecR, SURF.valNELE);
        
        %% Creating and solving WD-Matrix
        [matWD, WAKE.vecWR] = fcnWDWAKE([1:WAKE.valWNELE]', WAKE.matWADJE, WAKE.vecWDVEHVSPN, WAKE.vecWDVESYM, WAKE.vecWDVETIP, WAKE.vecWKGAM, INPU.vecN);
        [WAKE.matWCOEFF] = fcnSOLVEWD(matWD, WAKE.vecWR, WAKE.valWNELE, WAKE.vecWKGAM, WAKE.vecWDVEHVSPN);
        
        %% Relaxing wake
        if valTIMESTEP > 2 && FLAG.RELAX == 1
            WAKE = fcnRELAXWAKE(valTIMESTEP, SURF, WAKE, COND, FLAG, INPU);
            
            % Creating and solving WD-Matrix
            [matWD, WAKE.vecWR] = fcnWDWAKE([1:WAKE.valWNELE]', WAKE.matWADJE, WAKE.vecWDVEHVSPN, WAKE.vecWDVESYM, WAKE.vecWDVETIP, WAKE.vecWKGAM, INPU.vecN);
            [WAKE.matWCOEFF] = fcnSOLVEWD(matWD, WAKE.vecWR, WAKE.valWNELE, WAKE.vecWKGAM, WAKE.vecWDVEHVSPN);
        end
        
        %% Forces
        [INPU, COND, MISC, VISC, WAKE, VEHI, SURF, OUTP] = fcnFORCES(valTIMESTEP, FLAG, INPU, COND, MISC, VISC, WAKE, VEHI, SURF, OUTP);
        
    end
    
    %% Post-timestep outputs
    if FLAG.PRINT == 1
        fcnPRINTOUT(FLAG.PRINT, valTIMESTEP, INPU.valVEHICLES, OUTP.vecCL, OUTP.vecCDI, OUTP.vecCTCONV, MISC.vecROTORJ, VEHI.vecROTORVEH, 1)
    end
    
    if FLAG.GIF == 1 % Creating GIF (output to GIF/ folder by default)
        fcnGIF(FLAG.VERBOSE, valTIMESTEP, SURF.valNELE, SURF.matDVE, SURF.matVLST, SURF.matCENTER, VISC.matFUSEGEOM, WAKE.valWNELE, WAKE.matWDVE, WAKE.matWVLST, WAKE.matWCENTER, WAKE.vecWPLOTSURF, 1);
    end
    
    if FLAG.PREVIEW ~= 1 && max(SURF.vecDVEROTOR) > 0
        temp_cdi = fcnTIMEAVERAGE(OUTP.vecCDI(:,end), COND.vecROTORRPM, COND.valDELTIME);
    end
end

if FLAG.PRINT == 1 && FLAG.PREVIEW == 0
    fprintf('VISCOUS CORRECTIONS => CLv = %0.4f \tCD = %0.4f \n', OUTP.vecCLv(end,:), OUTP.vecCD(end,:))
    fprintf('\n');
end

%% Plotting
fcnPLOTPKG(FLAG, SURF, VISC, WAKE, COND)

OUTP.vecDVEAREA = SURF.vecDVEAREA;
OUTP.valAREA = INPU.vecAREA;
OUTP.matGEOM = INPU.matGEOM;