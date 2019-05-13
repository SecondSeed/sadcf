function score = calculateOpticalScore(flow, last_pos, last_rect, rect_pos)
%   Ximing Xiang 2018
p = rect_pos([2, 1]) + rect_pos([4, 3]) / 2;
rect = rect_pos([4, 3]);
four_point = getFourPoint(p, rect);
four_point = four_point - last_pos;
yv = four_point(:, 1);
xv = four_point(:, 2);
slice = getSlice(size(flow.Vx),last_pos, last_rect);
oflow.Vx = flow.Vx(slice.y, slice.x);
oflow.Vy = flow.Vy(slice.y, slice.x);

for i = 1 : size(oflow.Vx, 2)
    oflow.Vx(:, i) = oflow.Vx(:, i) + i;
end

for i = 1 : size(oflow.Vy, 1)
    oflow.Vy(i, :) = oflow.Vy(i, :) + i;
end
res = inpolygon(oflow.Vx, oflow.Vy, xv, yv);

in = sum(res(:) == 1);
all = size(oflow.Vx, 1) * size(oflow.Vy, 2);
score = in / all;

function rect = getFourPoint(pos, rect)

rect = [pos - rect / 2];
rect = [rect; [pos(1) + rect(1), pos(2) - rect(2)]];
rect = [rect; pos + rect / 2];
rect = [rect; [pos(1) - rect(1), pos(2) + rect(2)]];