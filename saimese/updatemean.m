function [all, count] = updatemean(all, param, fsim, sim, count)
if sim > fsim * param
    all = all + sim;
    count = count + 1;
end