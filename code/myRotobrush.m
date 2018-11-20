% MyRotobrush.m  - UMD CMSC426, Fall 2018
% This is the main script of your rotobrush project.
% We've included an outline of what you should be doing, and some helful visualizations.
% However many of the most important functions are left for you to implement.
% Feel free to modify this code as you see fit.

% Some parameters you need to tune:
WindowWidth = 14;  
ProbMaskThreshold = 0.4; 
NumWindows= 60; 
BoundaryWidth = 2;

% Load images:
fpath = '../input';
files = dir(fullfile(fpath, '*.jpg'));
imageNames = zeros(length(files),1);
images = cell(length(files),1);

for i=1:length(files)
    imageNames(i) = str2double(strtok(files(i).name,'.jpg'));
end

imageNames = sort(imageNames);
imageNames = num2str(imageNames);
imageNames = strcat(imageNames, '.jpg');

for i=1:length(files)
    images{i} = im2double(imread(fullfile(fpath, strip(imageNames(i,:)))));
end

% NOTE: to save time during development, you should save/load your mask rather than use ROIPoly every time.
% mask = roipoly(images{1});
mask = rgb2gray(imread('input/Mask1.png')) > 0;
imshow(imoverlay(images{1}, boundarymask(mask,8),'red'));
figure
set(gca,'position',[0 0 1 1],'units','normalized')
F = getframe(gcf);
[I,~] = frame2im(F);
imwrite(I, fullfile(fpath, strip(imageNames(1,:))));
outputVideo = VideoWriter(fullfile(fpath,'video.mp4'),'MPEG-4');
open(outputVideo);
writeVideo(outputVideo,I);

% Sample local windows and initialize shape+color models:
[mask_outline, LocalWindows] = initLocalWindows(images{1},mask,NumWindows,WindowWidth,true);

LocalWindows = [LocalWindows(:,2)  LocalWindows(:,1)];
ColorModels = ...
    initColorModels(images{1},mask,mask_outline,LocalWindows,BoundaryWidth,WindowWidth);

% You should set these parameters yourself:
%%% **** %%%
fcutoff = 0.7;
SigmaMin = 1;
SigmaMax = WindowWidth;
R = 6;
%%% **** %%%
A = (SigmaMax - SigmaMin)/(1 - fcutoff)^R;
ShapeConfidences = ...
    initShapeConfidences(LocalWindows,ColorModels,...
    WindowWidth, SigmaMin, A, fcutoff, R);

% Show initial local windows and output of the color model:
imshow(images{1})
hold on
showLocalWindows(LocalWindows,WindowWidth,'r.');
figure
hold off
set(gca,'position',[0 0 1 1],'units','normalized')
F = getframe(gcf);
[I,~] = frame2im(F);

%showColorConfidences(images{1},mask_outline,ColorModels.Confidences,LocalWindows,WindowWidth);

%%% MAIN LOOP %%%
% Process each frame in the video.
for prev=1:(length(files)-1)
    curr = prev+1;
    fprintf('Current frame: %i\n', curr)
    
    %%% Global affine transform between previous and current frames:
    [warpedFrame, warpedMask, warpedMaskOutline, warpedLocalWindows] = calculateGlobalAffine(images{prev}, images{curr}, mask, LocalWindows);
    fprintf("    Affine calculated.\n")
    %%% Calculate and apply local warping based on optical flow:
    NewLocalWindows = ...
        localFlowWarp(warpedFrame, images{curr}, warpedLocalWindows,warpedMask,WindowWidth);
    
    fprintf("    Local flow warp calculated.\n")
    
    % Show windows before and after optical flow-based warp:
    imshow(images{curr});
    hold on
    showLocalWindows([warpedLocalWindows(:,2) warpedLocalWindows(:,1)],WindowWidth,'r.');
    showLocalWindows([NewLocalWindows(:,2) NewLocalWindows(:,1)],WindowWidth,'b.');
    hold off
    
    %%% UPDATE SHAPE AND COLOR MODELS:
    % This is where most things happen.
    % Feel free to redefine this as several different functions if you prefer.
    [ ...
        mask, ...
        LocalWindows, ...
        ColorModels, ...
        ShapeConfidences, ...
    ] = ...
    updateModels(...
        NewLocalWindows, ...
        LocalWindows, ...
        images{curr}, ...
        warpedMask, ...
        warpedMaskOutline, ...
        WindowWidth, ...
        ColorModels, ...
        ShapeConfidences, ...
        ProbMaskThreshold, ...
        fcutoff, ...
        SigmaMin, ...
        R, ...
        A ...
    );

    mask_outline = bwperim(mask,4);

    % Write video frame:
    imshow(mask);
    set(gca,'position',[0 0 1 1],'units','normalized')
    F = getframe(gcf);
    [I,~] = frame2im(F);
    imwrite(I, fullfile(fpath, strip(imageNames(curr,:))));
    writeVideo(outputVideo,I);

    imshow(images{curr})
    hold on
    showLocalWindows(LocalWindows,WindowWidth,'r.');
    hold off
    set(gca,'position',[0 0 1 1],'units','normalized')
    F = getframe(gcf);
    [I,~] = frame2im(F);
end

close(outputVideo);
