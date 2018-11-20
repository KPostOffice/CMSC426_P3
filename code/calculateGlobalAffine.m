function [WarpedFrame, WarpedMask, WarpedMaskOutline, WarpedLocalWindows] = calculateGlobalAffine(IMG1,IMG2,Mask,Windows)
% CALCULATEGLOBALAFFINE: finds affine transform between two frames, and applies it to frame1, the mask, and local windows.
    F1 = detectHarrisFeatures(rgb2gray(IMG1).');
    F1_fg_loc = [];
    F1_fg_met = [];
    F1_fg_count = 0;
    
    for i = 1:F1.Count
        x = F1.Location(i,1);
        y = F1.Location(i,2);
        
        if Mask(floor(x), floor(y)) >0
            F1_fg_loc = [F1_fg_loc ; x y];
            F1_fg_met = [F1_fg_met ; F1.Metric(i)];
            F1_fg_count = F1_fg_count + 1;
        end
    end
    F1_new = cornerPoints(F1_fg_loc);
    F1_new.Metric = F1_fg_met;
    [feat1, valid_p1] = extractFeatures(rgb2gray(IMG1).', F1_new);
    
    F2 = detectHarrisFeatures(rgb2gray(IMG2).');
    [feat2, valid_p2] = extractFeatures(rgb2gray(IMG2).', F2);
    
    indexPairs = matchFeatures(feat1, feat2);
    matchedP1 = valid_p1(indexPairs(:,1), :);
    matchedP2 = valid_p2(indexPairs(:,2), :);
    
    tform = estimateGeometricTransform(matchedP1,matchedP2, 'affine');
    WarpedMask = imwarp(Mask, tform, 'OutputView', imref2d(size(Mask))); 
    WarpedMaskOutline = bwperim(Mask, 4);
    WarpedFrame = imwarp(IMG1, tform, 'OutputView', imref2d(size(IMG1)));
    WarpedLocalWindows = transformPointsForward(tform, Windows);
end

