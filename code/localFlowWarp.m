function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO
    estimateFlow(opticFlow, WarpedPrevFrame);
    flow = estimateFlow(CurrentFrame);
    num_windows = size(LocalWindows, 1);
    NewLocalWindows = size(LocalWindows);
    for i = 1:num_windows
        transform = [0 0];
        t_count = 0;
        for j = (-Width/2):(Width/2)
            for k = (-Width/2):(Width/2)
                x_pos = LocalWindows(i, 1) + j;
                y_pos = LocalWindows(i, 2) + k;
                if Mask(x_pos, y_pos) == 1
                    transform = transform + flow(x_pos, y_pos);
                    t_count = t_count + 1;
                end
            end
        end
        transform = transform/t_count;
        NewLocalWindows(i,:) = LocalWindows + transform;
    end
end

