function overlap_score = calculateMeanOverlap(rect)
overlap = 0;
for i = 1 : size(rect, 1) - 1
    for j = i + 1 : size(rect, 1)
        overlap = overlap + calcRectInt(rect(i, :), rect(j, :));
    end
end
overlap_score = overlap / nchoosek(size(rect, 1), 2);
