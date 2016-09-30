function [hFig2] = fcnPLOTBODY(verbose, valNELE, matDVE, matVLST, matCENTER)

hFig2 = figure(2);
clf(2);

patch('Faces',matDVE,'Vertices',matVLST,'FaceColor','r')
hold on


alpha(0.5)

if verbose == 1
    for ii = 1:valNELE
        str = sprintf('%d',ii);
        text(matCENTER(ii,1),matCENTER(ii,2),matCENTER(ii,3),str,'Color','k','FontSize',15);
    end
    
%     for ii = 1:length(matVLST(:,1))
%         str = sprintf('%d',ii);
%         text(matVLST(ii,1),matVLST(ii,2),matVLST(ii,3),str,'Color','g','FontSize',15);
%     end
        
end

hold off

box on
grid on
axis equal

xlabel('X-Dir','FontSize',15);
ylabel('Y-Dir','FontSize',15);
zlabel('Z-Dir','FontSize',15);