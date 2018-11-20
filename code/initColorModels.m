function ColorModels = initColorModels(IMG, Mask, MaskOutline, LocalWindows, BoundaryWidth, WindowWidth)
% INITIALIZAECOLORMODELS Initialize color models.  ColorModels is a struct you should define yourself.
%
% Must define a field ColorModels.Confidences: a cell array of the color confidence map for each local window.
    D = bwdist(MaskOutline);
    num_windows = (size(LocalWindows,1));
    labIMG = rgb2lab(IMG);
    
    %ColorModels{i,1} is the known segmentation
    %ColorModels{i,2} is probability of foreground
    %ColorModels{i,3} is seperatibility
    %ColorModels{i,4} is the F_gmdist
    %ColorModels{i,5} is the B_gmdist
    ColorModels.Confidences = cell(num_windows,1);
    ColorModels.Segment = cell(num_windows,1);
    ColorModels.Seperate = cell(num_windows,1);
    ColorModels.Foreground = cell(num_windows,1);
    ColorModels.Foreground = cell(num_windows,1);
    
    MaskBoundary = bwperim(Mask, 1);
    
    for i = 1:num_windows
        F_Points = [];
        B_Points = [];
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                x_pos = LocalWindows(i, 1) - WindowWidth/2 + j;
                y_pos = LocalWindows(i, 2) - WindowWidth/2 + k;
                if ~ MaskBoundary(x_pos, y_pos) == 1
                    if Mask(x_pos, y_pos) ~= 0
                        F_Points = [F_Points; reshape(labIMG(x_pos, y_pos,:), 1, 3)]; 
                    else
                        B_Points = [B_Points; reshape(labIMG(x_pos, y_pos,:), 1, 3)];
                    end
                end
            end
        end
        ColorModels.Foreground{i} = F_Points;
        ColorModels.Background{i} = B_Points;
    end
    
    
    for i = 1:num_windows
        x_pos = LocalWindows(i, 1) - WindowWidth/2;
        y_pos = LocalWindows(i, 2) - WindowWidth/2;
        ColorModels.Segment{i} = Mask(x_pos:x_pos+WindowWidth, y_pos:y_pos+WindowWidth);
        ColorModels.Confidences{i} = zeros(WindowWidth);
        numerator = 0;
        denominator = 0;
        gmm_f = fitgmdist(ColorModels.Foreground{i}, 1);
        gmm_b = fitgmdist(ColorModels.Background{i}, 1);
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                x_pos = LocalWindows(i, 1) + j - WindowWidth/2;
                y_pos = LocalWindows(i, 2) + k - WindowWidth/2;
                f_poster = gmm_f.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                b_poster = gmm_b.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                pc = f_poster/(f_poster + b_poster);
                ColorModels.Confidences{i}(j,k) = pc;
                lil_omega = exp(-(D(x_pos, y_pos))^2/(WindowWidth/2)^2);
                numerator = numerator + abs(pc-Mask(x_pos, y_pos))*lil_omega;
                denominator = denominator + lil_omega;
            end
        end
        ColorModels.Seperate{i} = 1 - numerator/denominator;
        
    end
    
    
end

