function [saimeseExp, expand_threshold] = expandSpace(saimeseExp, cpu_im, lastpos, lastSz, firstFeature, saimese, s_x, avgChans, meanFirstSimilarity, expand_threshold)
saimeseExp.chooseExpandPos = 0;
[pos, sz, similarity, response] = excuteMultiScaleSearch(cpu_im, lastpos, lastSz, firstFeature, saimese, s_x, avgChans);
if similarity < expand_threshold * meanFirstSimilarity
    [tmp_pos, tmp_sz, tmp_sim, expand_response] = excuteLargeScaleSearch(cpu_im, lastpos, lastSz, firstFeature, saimese, s_x, avgChans);
    expand_threshold = expand_threshold - saimese.descend;
    if expand_threshold < saimese.down
        expand_threshold = saimese.down;
    end
    if tmp_sim > saimese.boundthreshold * similarity
        pos = tmp_pos;
        sz = tmp_sz;
        similarity = tmp_sim;
        saimeseExp.chooseExpandPos = 1;
    end
else
    expand_threshold = expand_threshold + saimese.ascend;
    if expand_threshold > saimese.up
        expand_threshold = saimese.up;
    end
    expand_response = [];
end
disp = sqrt(sum((pos - lastpos) .^ 2)) / sqrt(prod(lastSz));
if disp > 0.25
    saimeseExp.expand = 1;
else
    saimeseExp.expand = 0;
end
saimeseExp.pos = pos;
saimeseExp.sz = sz;
saimeseExp.similarity = similarity;
saimeseExp.response = response;
saimeseExp.expand_response = expand_response;
saimeseExp.rect_position = [saimeseExp.pos([2,1]) - saimeseExp.sz([2,1])/2, saimeseExp.sz([2,1])];
saimeseExp.center = [saimeseExp.rect_position(1) + (saimeseExp.rect_position(3)-1)/2  saimeseExp.rect_position(2) + (saimeseExp.rect_position(4)-1)/2];