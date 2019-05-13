function expert = normRobust(expert, expertNum)
maxv = max([expert(:).RobScore]);
minv = min([expert(:).RobScore]);
if maxv == minv
    for i = 1: expertNum
        expert(i).normRobScore = 1;
    end
else
    for i = 1 : expertNum
        expert(i).normRobScore = (expert(i).RobScore - minv)/(maxv - minv);
    end
end
end