function [matWAKEGEOM, vecWDVEHVSPN, vecWDVEHVCRD, vecWDVEROLL, vecWDVEPITCH, vecWDVEYAW, vecWDVELESWP, ...
    vecWDVEMCSWP, vecWDVETESWP, vecWDVEAREA, matWDVENORM, matWVLST, matWDVE, valWNELE, matWCENTER] ...
    = fcnCREATEWAKE(matNEWWAKE, matWAKEGEOM)

matWAKEGEOM = cat(1, matWAKEGEOM, matNEWWAKE);

matWCENTER = mean(matWAKEGEOM,3);

[vecWDVEHVSPN, vecWDVEHVCRD, vecWDVEROLL, vecWDVEPITCH, vecWDVEYAW, vecWDVELESWP, vecWDVEMCSWP, vecWDVETESWP, vecWDVEAREA, matWDVENORM, ...
    matWVLST, matWDVE, valWNELE] = fcnDVECORNER2PARAM(matWCENTER, matWAKEGEOM(:,:,1), matWAKEGEOM(:,:,2), matWAKEGEOM(:,:,3), matWAKEGEOM(:,:,4));



end

