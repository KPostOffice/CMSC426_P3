function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO
    opticFlow = opticalFlowHS;
    estimateFlow(opticFlow, rgb2gray(WarpedPrevFrame));
    flow = estimateFlow(opticFlow, rgb2gray(CurrentFrame));
    num_windows = size(LocalWindows, 1);
    NewLocalWindows = size(LocalWindows);
    for i = 1:num_windows
        transform = [0 0];
        t_count = 0;
        for j = (-Width/2):(Width/2)
            for k = (-Width/2):(Width/2)
                x_pos = floor(LocalWindows(i, 1) + j);
                y_pos = floor(LocalWindows(i, 2) + k);
                
                
                if Mask(x_pos, y_pos) == 1
                    transform = transform + [flow.Vx(x_pos, y_pos) flow.Vy(x_pos,y_pos)]*flow.Magnitude(x_pos, y_pos);
                    t_count = t_count + 1;
                end
            end
        end
        transform = transform/t_count;
        NewLocalWindows(i,:) = LocalWindows(i,:) + transform;
    end
end

