function relative_disp = calculateRelativeDisp(origin_exp, expand_exp)
origin_center = [0, 0];
expand_center = [0, 0];
for i = 1 : size(origin_exp, 2)
    origin_center = origin_center + origin_exp(i).center;
    expand_center = expand_center + expand_exp(i).center;
end
origin_center = origin_center / size(origin_exp, 2);
expand_center = expand_center / size(expand_exp, 2);
sz = origin_exp(1).rect_position([3,4]);
relative_disp = sqrt(sum((origin_center - expand_center) .^ 2)) / sqrt(prod(sz));
