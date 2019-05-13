function finalExp = calculateCfSimilarity(finalExp, pos, response, s_x, saimese)
merge_response = max(response, [], 3);
for i = 1 : size(finalExp, 2)
    finalExp(i).fsim = calculateSimilarityScore(finalExp(i).pos, pos, merge_response, s_x, saimese);
end
