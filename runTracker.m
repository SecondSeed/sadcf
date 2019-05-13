clc;
clear all;
addpath('./tracker');                    
addpath('./utility');
addpath('model','matconvnet/matlab');
addpath('saimese');
vl_setupnn();
%%% please recompile the MatConvNet toolbox  
%vl_compilenn('enableGpu',true, 'CudaRoot', 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.0');
params.visualization = 1;                  % show output bbox on frame




%% DCF related 
params.hog_cell_size = 4;
params.fixed_area = 150^2;                 % standard area to which we resize the target
params.n_bins = 2^5;                       % number of bins for the color histograms (bg and fg models)
params.lr_pwp_init = 0.01;                 % bg and fg color models learning rate 
params.inner_padding = 0.2;                % defines inner area used to sample colors from the foreground
params.output_sigma_factor = 0.1;          % standard deviation for the desired translation filter output 
params.lambda = 1e-4;                      % regularization weight
params.lr_cf_init = 0.01;                  % DCF learning rate
params.period = 5;                         % time period, \Delta t
params.update_thres = 0.6;                 % threshold for adaptive update
params.expertNum = 8;  
params.cfExpertNum = 7;
params.simId = 8;


%% scale related
params.hog_scale_cell_size = 4;            % from DSST 
params.learning_rate_scale = 0.025;      
params.scale_sigma_factor = 1/2;
params.num_scales = 33;       
params.scale_model_factor = 1.0;
params.scale_step = 1.02;
params.scale_model_max_area = 32*16;

%% sat param
saimese_param.descend = 0.05;
saimese_param.ascend = 0.01;
saimese_param.up = 0.85;
saimese_param.down = 0.05;
saimese_param.boundthreshold = 0.8;
saimese_param.dispthreshold = 0.3;
saimese_param.spacethreshold = 0.4;
saimese_param.scoreparam = [0.7, 0.3];

%% load sequence
videoname = 'Woman'; 
img_path = 'sequence/Woman/img/';
base_path = '.\sequence\';
[img_files, pos, target_sz, video_path] = load_video_info(base_path, videoname);
%% start trackerMain.m
im = imread([img_path img_files{1}]);
% is a grayscale sequence ?
if(size(im,3)==1)
    params.grayscale_sequence = true;
end
if(size(im,3)==3)
    params.grayscale_sequence = false;
end
params.img_files = img_files;
params.img_path = img_path;
% init_pos is the centre of the initial bounding box
params.init_pos = pos;
params.target_sz = target_sz;
[params, bg_area, fg_area, area_resize_factor] = initializeAllAreas(im, params);
if params.visualization
    params.videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
end
% ³õÊ¼»¯ÍøÂç
saimese = initial_saimese(saimese_param);
% start the actual tracking
result = trackerMain(params, im, bg_area, fg_area, area_resize_factor, saimese);

