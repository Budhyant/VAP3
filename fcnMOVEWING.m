function [matVLST, matCENTER, matNEWWAKE] = fcnMOVEWING(valALPHA, valBETA, valDELTIME, matVLST, matCENTER, matDVE, vecDVETE)
% This function moves a wing (NOT rotor) by translating all of the vertices
% in the VLST and the in-centers of each triangle in CENTER.

% INPUT:
%   valALPHA - Angle of attack for this move (radians)
%   valBETA - Sideslip angle for this move (radians)
%   valDELTIME - Timestep size for this move
%   matVLST - Vertex list from fcnTRIANG
%   matCENTER - In-center list from fcnTRIANG
%   matELST - List of edges from fcnTRIANG
%   vecTE - List of trailing edge edges
% OUTPUT:
%   matVLST - New vertex list with moved points
%   matCENTER - New in-center list with moved points
%   matVUINF - Freestream values at each of the vertices
%   matCUINF - Freestream values at each of the in-centers
%   matNEWWAKE - Outputs a 4 x 3 x n matrix of points for the wake DVE generation

uinf = 1;

uinf = [uinf*cos(valALPHA)*cos(valBETA) uinf*sin(valBETA) uinf*sin(valALPHA)*cos(valBETA)];

translation = valDELTIME.*uinf;

% Old trailing edge vertices
old_te = permute(reshape(matVLST(matDVE(vecDVETE>0,4:-1:3),:)',3,2,[]),[2 1 3]);

matVLST = matVLST - repmat(translation, length(matVLST(:,1)), 1);
matCENTER = matCENTER - repmat(translation, length(matCENTER(:,1)), 1);

% New trailing edge vertices
new_te = permute(reshape(matVLST(matDVE(vecDVETE>0,4:-1:3),:)',3,2,[]),[2 1 3]);

% These vertices will be used to calculate the wake HDVE geometry
matNEWWAKE = cat(1, new_te, old_te);