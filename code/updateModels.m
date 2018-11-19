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

    eps = 0.1
    
    labIMG = rgb2lab(CurrentFrame);

    num_windows = size(NewLocalWindows, 1);
    for i = 1:num_windows
        gmm_historic_f = fitgmdist(ColorModels{i,4}, 2);
        gmm_historic_b = fitgmdist(ColorModels{i,5}, 2); 
        historic_count = 0;  % Must be compared to new_count later to determine change in number of foreground pixels
        new_data_f = ColorModels.Foreground{i};  % Create copy of historic data to add to
        new_data_b = ColorModels.Background{i};  %  "                                 "
        for j = (-WindowWidth/2):WindowWidth/2  %  Iterates over full windowidth
            for k = (-WindowWidth/2):WindowWidth/2
                x_pos = NewLocalWindows(i,1) + j;  % calculates x position based on window location
                y_pos = NewLocalWindows(i,2) + k;  % calculates y position based on window location
                f_poster = gmm_historic_f.posterior(labIMG(x_pos, y_pos,:));
                b_poster = gmm_historic_b.posterior(labIMG(x_pos, y_pos,:));
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
        gmm_new_f = fitgmdist(new_data_f, 2);  % create gmm's using new data as well
        gmm_new_b = fitgmdist(new_data_b, 2);
        for j = (-WindowWidth)/2:WindowWidth/2
            for k = (-WindowWidth)/2:WindowWidth/2
                x_pos = NewLocalWindows(i,1) + j;
                y_pos = NewLocalWindows(i,2) + k;
                f_poster = gmm_new_f.posterior(labIMG(x_pos, y_pos,:));
                b_poster = gmm_new_b.posterior(labIMG(x_pos, y_pos,:));
                pc = f_poster/(f_poster + b_poster);
                if pc > 0.75
                    new_count = new_count + 1;
                end
            end
        end
        
        if abs(new_count - old_count)/old_count < 0.05
            ColorModels.Foreground{i} = new_data_f;
            ColorModels.Background{i} = new_data_b;
            x_pos = LocalWindows(i, 1) - WindowWidth/2;
            y_pos = LocalWindows(i, 2) - WindowWidth/2;
            ColorModels.Segment{i} = WarpedMask(x_pos:x_pos+WindowWidth, y_pos:y_pos+WindowWidth);
            ColorModels.Confidences{i} = zeros(WindowWidth);
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
    
    for i = 1:num_windows
        ShapeConfidences{i} = zeros(WindowWidth);
        D = bwdist(bwperim(ColorModels.Segment{i}));
        c_conf = ColorModels.Seperate{i};
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                if c_conf > fcutoff
                    sig = SigmaMin + A*(c_conf - fcutoff)^R;
                else
                    sig = sigMin;
                end
                ShapeConfidences{i}(j,k) = 1 - exp(-(D(j,k)^2)/sig^2);
            end
        end
    end
    
    numerators = zeros(size(CurrentFrame));
    denominators = zeros(size(CurrentFrame));
    
    for i = 1:num_windows
        gmm_f = fitgmdist(ColorModels.Foreground{i}, 2);
        gmm_b = fitgmdist(ColorModels.Background{i}, 2);
        for j = 1:WindowWidth
            for k = 1:WindowWidth
                x_pos = NewLocalWindows(i, 1) + j - WindowWidth/2;
                y_pos = NewLocalWindows(i, 2) + k - WindowWidth/2;
                
                dist = sqrt((x_pos - NewLocalWindows(i,1))^2 + ...
                    (y_pos - NewLocalWindows(i,2))^2);
                
                f_poster = gmm_f.posterior(labIMG(x_pos, y_pos,:));
                b_poster = gmm_b.posterior(labIMG(x_pos, y_pos,:));
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
    
    Z = denominators == 0;
    denominators(Z) = 1;
    
    [height, width] = size(CurrentFrame);
    for i = 1:height
        for j = 1:width
            if numerators(i,j) == 0
                numerators(i,j) = WarpedMask(i,j);
            end
        end
    end
    
    PB = numerators ./ denominators;
    
    mask = PB > ProbMaskThreshold;
    
    LocalWindows = NewLocalWindows;
end

