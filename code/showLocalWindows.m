function [] = showLocalWindows(LocalWindows,Width,Type)

for i = 1:length(LocalWindows)
    x = floor(LocalWindows(i,1));
    y = floor(LocalWindows(i,2));
    
    plot(x, y, Type);
    rectangle('Position', [(x - floor(Width/2)) (y - floor(Width/2)) Width Width]);
end


end

