function pos = calculatePosition(responseMap, s_x, last_position, saimese)
[r_max, c_max] = find(responseMap == max(responseMap(:)), 1);
[r_max, c_max] = avoid_empty_position(r_max, c_max, saimese);
p_corr = [r_max, c_max];
% Convert to crop-relative coordinates to frame coordinates
% displacement from the center in instance final representation ...
disp_instanceFinal = p_corr - ceil(saimese.scoreSize*saimese.responseUp/2);
% ... in instance input ...
disp_instanceInput = disp_instanceFinal * saimese.totalStride / saimese.responseUp;
% ... in instance original crop (in frame coordinates)
disp_instanceFrame = disp_instanceInput * s_x / saimese.instanceSize;
% position within frame in frame coordinates
pos = last_position + disp_instanceFrame;
end

function [r_max, c_max] = avoid_empty_position(r_max, c_max, params)
    if isempty(r_max)
        r_max = ceil(params.scoreSize/2);
    end
    if isempty(c_max)
        c_max = ceil(params.scoreSize/2);
    end
end