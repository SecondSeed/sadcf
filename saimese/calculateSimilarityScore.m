function similarityScore = calculateSimilarityScore(pos, last_pos, saimese_response, s_x, saimese)
disp = pos - last_pos;
disp_instanceInput = disp * saimese.instanceSize / s_x;
disp_instanceFinal = disp_instanceInput * saimese.responseUp / saimese.totalStride;
p_corr = disp_instanceFinal + saimese.scoreSize * saimese.responseUp / 2;
p_corr = ceil(p_corr);
p_corr = avoid_overstep(p_corr, saimese);
% response_size = size(saimese_response, 1);
% response_center = ceil([response_size, response_size] / 2);
% disp = disp * response_size / s_x;
% response_pos = ceil(response_center + disp);
%cpu_response = gather(saimese_response);

similarityScore = saimese_response(p_corr(1), p_corr(2));
end

function cor = avoid_overstep(cor, saimese)
cor(cor(:) < 1) = 1;
cor(cor(:) > saimese.scoreSize*saimese.responseUp) = saimese.scoreSize*saimese.responseUp;
end

%     [r_max, c_max] = find(responseMap == max(responseMap(:)), 1);
%     [r_max, c_max] = avoid_empty_position(r_max, c_max, p);
%     p_corr = [r_max, c_max];
%     % Convert to crop-relative coordinates to frame coordinates
%     % displacement from the center in instance final representation ...
%     disp_instanceFinal = p_corr - ceil(p.scoreSize*p.responseUp/2);
%     % ... in instance input ...
%     disp_instanceInput = disp_instanceFinal * p.totalStride / p.responseUp;
%     % ... in instance original crop (in frame coordinates)
%     disp_instanceFrame = disp_instanceInput * s_x / p.instanceSize;
%     % position within frame in frame coordinates
%     newTargetPosition = targetPosition + disp_instanceFrame;