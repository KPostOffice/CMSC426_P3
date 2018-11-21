function ShapeConfidences = initShapeConfidences(LocalWindows, ColorConfidences, WindowWidth, SigmaMin, A, fcutoff, R)
% INITSHAPECONFIDENCES Initialize shape confidences.  ShapeConfidences is a struct you should define yourself.
    num_windows = size(LocalWindows, 1);
    ShapeConfidences = cell(num_windows, 1);
    for i = 1:num_windows
        ShapeConfidences{i} = zeros(WindowWidth);
        D = bwdist(bwperim(ColorConfidences.Segment{i}));
        c_conf = ColorConfidences.Seperate{i};
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
end
