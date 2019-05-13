function score = calculateCfExpScore(cf_exp, saimeseExp, scoreparam)
response_score = 0;
cf_num = size(cf_exp, 2);
saimese_num = size(saimeseExp, 2);
for i = 1 : cf_num
    response_score = response_score + cf_exp(i).max_response;
end
response_score = response_score / size(cf_exp, 2);
rect_num = cf_num + saimese_num;
rect = zeros(rect_num, 4);
for i = 1 : cf_num
    rect(i, :) = cf_exp(i).rect_position;
end
for i = cf_num + 1 : cf_num + saimese_num
    rect(i, :) = saimeseExp(i - cf_num).rect_position;
end
overlap_score = calculateMeanOverlap(rect);
score = scoreparam(1) * response_score + scoreparam(2) * overlap_score;
