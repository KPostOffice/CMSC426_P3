function [mask, LocalWindows, ColorModels, ShapeConfidences] = ...
    updateModels(...
        NewLocalWindows, ...
        LocalWindows, ...
        CurrentFrame, ...
        warpedMask, ...   % L of T+1
        warpedMaskOutline, ...
        WindowWidth, ...
        ColorModels, ...
        ShapeConfidences, ...
        ProbMaskThreshold, ... % tuned
        fcutoff, ...    % tuned
        SigmaMin, ...  % tuned
        R, ...  % Check on piazza for what this is (tuned)
        A ...  % Check on piazza for what this is (tuned)
    )
% UPDATEMODELS: update shape and color models, and apply the result to generate a new mask.
% Feel free to redefine this as several different functions if you prefer.

    eps = 0.1;
    
    labIMG = rgb2lab(CurrentFrame);

    num_windows = size(NewLocalWindows, 1);
    fprintf("    1)Working on window:")
    for i = 1:num_windows
        fprintf(" %i", i)
        gmm_historic_f = fitgmdist(ColorModels.Foreground{i}, 1);
        gmm_historic_b = fitgmdist(ColorModels.Background{i}, 1); 
        historic_count = 0;  % Must be compared to new_count later to determine change in number of foreground pixels
        new_data_f = ColorModels.Foreground{i};  % Create copy of historic data to add to
        new_data_b = ColorModels.Background{i};  %  "                                 "
        for j = 1:WindowWidth  %  Iterates over full windowidth
            for k = 1:WindowWidth
                x_pos = floor(NewLocalWindows(i,1) - WindowWidth/2 + j);  % calculates x position based on window location
                y_pos = floor(NewLocalWindows(i,2) - WindowWidth/2 + k);  % calculates y position based on window location
                f_poster = gmm_historic_f.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                b_poster = gmm_historic_b.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                pc = f_poster/(f_poster + b_poster);  % probability of foreground pixel based on posterior probablities
                if pc > 0.75
                    new_data_f = [new_data_f; reshape(labIMG(x_pos, y_pos,:), 1, 3)];  % add new data
                    historic_count = historic_count + 1;
                elseif pc < 0.25  
                    new_data_b = [new_data_b; reshape(labIMG(x_pos, y_pos,:), 1, 3)];  % add new data
                end
            end
        end
        
        new_count = 0;  % to compare with old count
        gmm_new_f = fitgmdist(new_data_f, 1);  % create gmm's using new data as well
        gmm_new_b = fitgmdist(new_data_b, 1);
        for j = (-WindowWidth)/2:WindowWidth/2
            for k = (-WindowWidth)/2:WindowWidth/2
                x_pos = floor(NewLocalWindows(i,1) + j);
                y_pos = floor(NewLocalWindows(i,2) + k);
                f_poster = gmm_new_f.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                b_poster = gmm_new_b.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                pc = f_poster/(f_poster + b_poster);
                if pc > 0.75
                    new_count = new_count + 1;
                end
            end
        end
        
        if abs(new_count - historic_count)/historic_count < 0.05
            ColorModels.Foreground{i} = new_data_f;
            ColorModels.Background{i} = new_data_b;
            x_pos = floor(NewLocalWindows(i, 1) - WindowWidth/2);
            y_pos = floor(NewLocalWindows(i, 2) - WindowWidth/2);
            ColorModels.Segment{i} = WarpedMask(x_pos:x_pos+WindowWidth, y_pos:y_pos+WindowWidth);
            ColorModels.Confidences{i} = zeros(WindowWidth+1);
            numerator = 0;
            denominator = 0;
            gmm_f = fitgmdist(ColorModels.Foreground{i}, 2);
            gmm_b = fitgmdist(ColorModels.Background{i}, 2);
            for j = 1:WindowWidth
                for k = 1:WindowWidth
                    x_pos = NewLocalWindows(i, 1) + j - WindowWidth/2;
                    y_pos = NewLocalWindows(i, 2) + k - WindowWidth/2;
                    f_poster = gmm_f.posterior(labIMG(x_pos, y_pos,:));
                    b_poster = gmm_b.posterior(labIMG(x_pos, y_pos,:));
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
    fprintf("\n    2)Working on window: ");
    for i = 1:num_windows
        fprintf(" %i", i)
        ShapeConfidences{i} = zeros(WindowWidth);
        D = bwdist(bwperim(ColorModels.Segment{i}));
        c_conf = ColorModels.Seperate{i};
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                if c_conf > fcutoff
                    sig = SigmaMin + A*(c_conf - fcutoff)^R;
                else
                    sig = SigmaMin;
                end
                ShapeConfidences{i}(j,k) = 1 - exp(-(D(j,k)^2)/sig^2);
            end
        end
    end
    numerators = zeros(size(rgb2gray(CurrentFrame)));
    denominators = zeros(size(rgb2gray(CurrentFrame)));
    
    fprintf("\n    3) Working on window: ");    
    for i = 1:num_windows
        fprintf(" %i", i)
        gmm_f = fitgmdist(ColorModels.Foreground{i}, 1);
        gmm_b = fitgmdist(ColorModels.Background{i}, 1);
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                x_pos = floor(NewLocalWindows(i, 1) + j - WindowWidth/2);
                y_pos = floor(NewLocalWindows(i, 2) + k - WindowWidth/2);
                
                dist = sqrt((x_pos - NewLocalWindows(i,1))^2 + ...
                    (y_pos - NewLocalWindows(i,2))^2);
                
                f_poster = gmm_f.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                b_poster = gmm_b.posterior(reshape(labIMG(x_pos, y_pos,:), 1, 3));
                pc = f_poster/(f_poster + b_poster);
                
                n = ShapeConfidences{i}(j,k)*warpedMask(x_pos,y_pos) + ...
                    (1 - ShapeConfidences{i}(j,k))*pc;
                
                numerators(x_pos, y_pos) = numerators(x_pos, y_pos) + ...
                    n * (dist + eps)^(-1);
                
                denominators(x_pos, y_pos) = denominators(x_pos, y_pos) + ...
                    (dist + eps)^(-1);
            end
        end
    end
    
    fprintf("\n");  
    
    Z = denominators == 0;
    denominators(Z) = 1;
    
    [height, width] = size(rgb2gray(CurrentFrame));
    for i = 1:height
        for j = 1:width
            if numerators(i,j) == 0
                numerators(i,j) = warpedMask(i,j);
            end
        end
    end
    
    PB = numerators ./ denominators;
    
    mask = PB > ProbMaskThreshold;
    size(mask)
    LocalWindows = NewLocalWindows;
end

