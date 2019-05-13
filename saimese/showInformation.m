function showInformation(frame, Mode, simi, maxsimi, meansimi, lowcount, searchcount, scalefactor)
if Mode == 0
    text(10, 10,'search')
else
    text(10, 10,'normal')
end

formatSpec = 'frame: %d similarity: %f maxsimilarity: %f\n meansimilarity: %f lowcount: %d searchcount: %d scalefactor: %f';
str = sprintf(formatSpec, frame, simi, maxsimi, meansimi, lowcount, searchcount, scalefactor);
text(50, 10, str);