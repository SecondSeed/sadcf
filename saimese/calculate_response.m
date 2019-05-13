function [response, targetPosition, targetSize] = calculate_response(p, cpu_im, s_x, z_features, targetPosition, targetSize, avgChans, scales_array)
%   Luca Bertinetto, Jack Valmadre, Joao F. Henriques, 2016
%   Modified by Ximing Xiang, 2018
if nargin < 10, scales = [1];
else, scales = scales_array;
end
im = gpuArray(single(cpu_im));
% if grayscale repeat one channel to match filters size
if(size(im, 3)==1)
    im = repmat(im, [1 1 3]);
end
%scales = [1];
scaledInstance = s_x .* scales;
scaledTarget = [targetSize(1) .* scales; targetSize(2) .* scales];
% extract scaled crops for search region x at previous target position
x_crops = make_scale_pyramid(im, targetPosition, scaledInstance, p.instanceSize, avgChans,  p);
% evaluate the offline-trained network for exemplar x features
[newTargetPosition, newScale, response] = tracker_eval2(round(s_x),  z_features, x_crops, targetPosition,  p);
targetPosition = gather(newTargetPosition);
% scale damping and saturation
%s_x = max(min_s_x, min(max_s_x, (1-p.scaleLR)*s_x + p.scaleLR*scaledInstance(newScale)));

targetSize = (1-p.scaleLR)*targetSize + p.scaleLR*[scaledTarget(1,newScale) scaledTarget(2,newScale)];

