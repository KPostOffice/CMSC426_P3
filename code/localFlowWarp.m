function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO
    opticFlow = opticalFlowHS;
    estimateFlow(opticFlow, rgb2gray(WarpedPrevFrame));
    fprintf("        Got flow of first frame.\n");
    flow = estimateFlow(opticFlow, rgb2gray(CurrentFrame));
    fprintf("        Got flow of second frame.\n");
    num_windows = size(LocalWindows, 1);
    NewLocalWindows = size(LocalWindows);
    fprintf("        Entering window number:");
    MaskMag = flow.Magnitude .* Mask;
    MaskVx = MaskMag .* flow.Vy;
    MaskVy = MaskMag .* flow.Vx;
    h_w = floor(Width/2);
    for i = 1:num_windows
        fprintf(" %i", i);
        transform = [0 0];
        x_c = floor(LocalWindows(i,1));
        y_c = floor(LocalWindows(i,2));
        t_count = 0;
        Vx_window = MaskVx((x_c - h_w + 1):(x_c + h_w), (y_c - h_w + 1):(y_c+h_w));
        Vy_window = MaskVy((x_c - h_w + 1):(x_c + h_w), (y_c - h_w + 1):(y_c+h_w));
        x_count = sum(sum(Vx_window ~= 0));
        y_count = sum(sum(Vy_window ~= 0));
        x_change = 0;
        y_change = 0;
        
        if x_count ~= 0
            x_change = sum(sum(Vx_window))/x_count;
        end
        if y_count ~= 0
            y_change = sum(sum(Vy_window))/y_count;
        end
        
        NewLocalWindows(i,:) = LocalWindows(i,:) + [x_change y_change];
        %for j = 1:Width
         %   for k = 1:Width
          %      x_pos = floor(LocalWindows(i, 1) - Width/2 + j);
           %     y_pos = floor(LocalWindows(i, 2) - Width/2 + k);
                
                
            %    if Mask(x_pos, y_pos) == 1
             %       transform = transform + [flow.Vx(x_pos, y_pos) flow.Vy(x_pos,y_pos)]*flow.Magnitude(x_pos, y_pos);
                    t_count = t_count + 1;
              %  end
           % end
        %end
        %transform = transform/t_count;
        %NewLocalWindows(i,:) = LocalWindows(i,:) + transform;
    end
    fprintf("\n");
end

