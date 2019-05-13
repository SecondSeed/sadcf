function expert = mergeExpert(expert, finalExp, saimeseExp, frame, p)
cf_num = size(finalExp, 2);
saimese_num = size(saimeseExp, 2);
for i = 1 : cf_num
    expert(i).pos = finalExp(i).pos;
    expert(i).rect_position(frame, :) = finalExp(i).rect_position;
    expert(i).center(frame, :) = finalExp(i).center;
    expert(i).smooth(frame) = sqrt( sum((expert(i).center(frame,:)-expert(i).center(frame-1,:)).^2) );
    % smoothness between two frames
    expert(i).smoothScore(frame) = exp(- (expert(i).smooth(frame)).^2/ (2 * p.avg_dim.^2) );
    expert(i).fsim = finalExp(i).fsim;
end

for i = cf_num + 1 : cf_num + saimese_num
    expert(i).pos = saimeseExp(i - cf_num).pos;
    expert(i).rect_position(frame, :) = saimeseExp(i - cf_num).rect_position;
    expert(i).center(frame, :) = saimeseExp(i - cf_num).center;
    expert(i).smooth(frame) = sqrt( sum((expert(i).center(frame,:)-expert(i).center(frame-1,:)).^2) );
    % smoothness between two frames
    expert(i).smoothScore(frame) = exp(- (expert(i).smooth(frame)).^2/ (2 * p.avg_dim.^2) );
    expert(i).fsim = saimeseExp(i - cf_num).similarity;
end
