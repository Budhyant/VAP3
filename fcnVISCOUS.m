function [vecCLv, vecCD, vecPREQ, vecLD, matROTORCDP] = fcnVISCOUS(vecCL, vecCDI, vecVEHVINF, valAREA, valDENSITY, valKINV, vecDVENFREE, vecDVENIND, ...
    vecDVELFREE, vecDVELIND, vecDVESFREE, vecDVESIND, vecDVEPANEL, vecDVELE, vecDVEWING, vecN, vecM, vecDVEAREA, ...
    matCENTER, vecDVEHVCRD, cellAIRFOIL, flagVERBOSE, vecSYM, valVSPANELS, matVSGEOM, valFPANELS, matFGEOM, valFTURB, ...
    valFPWIDTH, valINTERF, vecDVEROLL, valVEHICLES, vecDVEVEHICLE, vecDVEROTOR, matUINF, valTIMESTEP, valMAXTIME, valDELTIME, vecROTORRPM, matDVE, matVLST,...
    matCOEFF, vecK, vecDVEHVSPN, vecDVEPITCH, vecDVEYAW, vecDVELESWP, vecDVETESWP,...
    valWNELE, matWDVE, matWVLST, matWCOEFF, vecWK, vecWDVEHVSPN, vecWDVEHVCRD, vecWDVEROLL, vecWDVEPITCH, vecWDVEYAW, vecWDVELESWP, vecWDVETESWP, valWSIZE, flagTRI, flagSTEADY, flagGPU, valNELE, vecPANELROTOR, flagVISCOUS)

vecCLv = nan(valVEHICLES,1);
vecCD = nan(valVEHICLES,1);
vecPREQ = nan(valVEHICLES,1);
vecLD = nan(valVEHICLES,1);
matROTORCDP = zeros(valNELE,3);

if flagVISCOUS == 1
    for i = 1:valVEHICLES

        idxvehwing = vecDVEWING > 0 & vecDVEVEHICLE == i; %(vecDVEWING.*vecDVEVEHICLE == i) > 0;

        if any(idxvehwing) && valTIMESTEP == valMAXTIME
            [vecCLv(i), vecCD(i), vecPREQ(i), vecLD(i)] = fcnVISCOUS_WING(vecCL(end), vecCDI(end), ...
                vecVEHVINF(i), valAREA, valDENSITY, valKINV, vecDVENFREE, vecDVENIND, ...
                vecDVELFREE, vecDVELIND, vecDVESFREE, vecDVESIND, vecDVEPANEL, vecDVELE, vecDVEWING.*uint8(idxvehwing), vecN, vecM, vecDVEAREA, ...
                matCENTER, vecDVEHVCRD, cellAIRFOIL, flagVERBOSE, vecSYM, valVSPANELS, matVSGEOM, valFPANELS, matFGEOM, valFTURB, ...
                valFPWIDTH, valINTERF, vecDVEROLL, matUINF);
        end


        idxvehrotor = vecDVEROTOR > 0 & vecDVEVEHICLE == i;
        if any(idxvehrotor)
            if valTIMESTEP > valMAXTIME - 1/(min(vecROTORRPM)*valDELTIME/60) % Only compute for last full rotor rotation
                % Compute induced velocity
                [matWUINF] = fcnINDVEL(matCENTER(idxvehrotor==1,:), valNELE, matDVE, matVLST, matCOEFF, vecK, vecDVEHVSPN, vecDVEHVCRD, vecDVEROLL, vecDVEPITCH, vecDVEYAW, vecDVELESWP, vecDVETESWP, vecSYM,...
                    valWNELE, matWDVE, matWVLST, matWCOEFF, vecWK, vecWDVEHVSPN, vecWDVEHVCRD, vecWDVEROLL, vecWDVEPITCH, vecWDVEYAW, vecWDVELESWP, vecWDVETESWP, valWSIZE, valTIMESTEP, flagTRI, flagSTEADY, flagGPU);

                [matROTORCDP(idxvehrotor,:)] = fcnVISCOUS_ROTOR(flagVERBOSE, ...
                    valKINV, vecDVEHVCRD(idxvehrotor==1), vecN(vecPANELROTOR>0), vecM(vecPANELROTOR>0), vecDVELE(idxvehrotor==1), vecDVEPANEL(idxvehrotor==1), cellAIRFOIL(vecPANELROTOR>0), vecDVENFREE(idxvehrotor==1)+vecDVENIND(idxvehrotor==1), vecDVEAREA(idxvehrotor==1),matUINF(idxvehrotor==1,:), matVLST, matDVE(idxvehrotor==1,:), matWUINF);
            end 
        end
    end 
end

end

