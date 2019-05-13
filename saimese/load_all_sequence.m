function [videonames, img_paths] = load_all_sequence(base_path)
all = dir(base_path);
% videonames = [];
% img_paths = [];
for i = 3 : size(all, 1)
    videonames(i - 2).str = all(i).name;
    img_paths(i - 2).str = [base_path all(i).name '/img/'];
end