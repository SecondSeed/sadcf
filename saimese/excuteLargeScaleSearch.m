function [pos, targetSize, Similarity, response] = excuteLargeScaleSearch(im, lastpos, lastSz, firstFeature, saimese, s_x, avgChans)
dis = 2 * lastSz;
anchor_pos = zeros(4, 2);
anchor_pos(1, :) = lastpos - dis / 2;
anchor_pos(2, :) = lastpos + dis / 2;
anchor_pos(3, :) = [lastpos(1) + dis(1), lastpos(2) - dis(2)];
anchor_pos(4, :) = [lastpos(1) - dis(1), lastpos(2) + dis(2)];
Similarity = -10;
for i = 1 : size(anchor_pos, 1)
    [tmp_pos, tmp_sz, tmp_sim, tmp_response] = excuteMultiScaleSearch(im, anchor_pos(i, :), lastSz, firstFeature, saimese, s_x, avgChans);
    if tmp_sim > Similarity
        pos = tmp_pos;
        targetSize = tmp_sz;
        Similarity = tmp_sim;
        response = tmp_response;
    end
end

