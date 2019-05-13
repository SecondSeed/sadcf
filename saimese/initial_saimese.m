function saimese = initial_saimese(param)
    global enableGPU;
    saimese.gpus = 1;
    saimese.descend = param.descend;
    saimese.ascend = param.ascend;
    saimese.up = param.up;
    saimese.down = param.down;
    saimese.boundthreshold = param.boundthreshold;
    saimese.dispthreshold = param.dispthreshold;
    saimese.spacethreshold = param.spacethreshold;
    saimese.scoreparam = param.scoreparam;
%     remove Scale for MCCT
    saimese.numScale = 3;
    saimese.scaleStep = 1.0375;
    saimese.scalePenalty = 0.9745;
    saimese.scaleLR = 0.59; % damping factor for scale update

    saimese.responseUp = 16; % upsampling the small 17x17 response helps with the accuracy
    saimese.windowing = 'cosine'; % to penalize large displacements
    saimese.wInfluence = 0.176; % windowing influence (in convex sum)
    saimese.net = '2016-08-17.net.mat';
    %% execution, visualization, benchmark
%     saimese.video = 'vot15_bag';
%     saimese.visualization = false;
%      saimese.gpus = 1;
%   ???????????
    saimese.bbox_output = false;
    saimese.fout = -1;
%   ???????????
    %% Params from the network architecture, have to be consistent with the training
    saimese.exemplarSize = 127;  % input z size
    saimese.instanceSize = 255;  % input x size (search region)
    saimese.candidateSize = 127; % input candidate size （similarity）
    saimese.scoreSize = 17;
    saimese.totalStride = 8;     % 不知道干嘛用的， 先留着
    saimese.contextAmount = 0.5; % context amount for the exemplar
    saimese.subMean = false;
    %% SiamFC prefix and ids
    saimese.prefix_z = 'a_'; % used to identify the layers of the exemplar
    saimese.prefix_x = 'b_'; % used to identify the layers of the instance
    saimese.prefix_c = 'a_';
    saimese.prefix_join = 'xcorr';
    saimese.prefix_adj = 'adjust';
    saimese.id_feat_z = 'a_feat';
    saimese.id_score = 'score';
    % Overwrite default parameters with varargin
    %saimese = vl_argparse(saimese, varargin);
% -------------------------------------------------------------------------------------------------

    % Get environment-specific default paths.
    saimese = env_paths_tracking(saimese);
    % Load ImageNet Video statistics
    if exist(saimese.stats_path,'file')
        stats = load(saimese.stats_path);
    else
        warning('No stats found at %s', saimese.stats_path);
        stats = [];
    end
    % Load two copies of the pre-trained network
    saimese.net_z = load_pretrained([saimese.net_base_path saimese.net], saimese.gpus);
    saimese.net_x = load_pretrained([saimese.net_base_path saimese.net], []); % 改了这个地方， 将[]改为saimese.gpus
    %net_c = net_z;
%     [imgFiles, targetPosition, targetSize] = load_video_info(saimese.seq_base_path, saimese.video);
%     nImgs = numel(imgFiles);
%     startFrame = 1;
    % Divide the net in 2
    % exemplar branch (used only once per video) computes features for the target
    remove_layers_from_prefix(saimese.net_z, saimese.prefix_x);
    remove_layers_from_prefix(saimese.net_z, saimese.prefix_join);
    remove_layers_from_prefix(saimese.net_z, saimese.prefix_adj);
    % instance branch computes features for search region x and cross-correlates with z features
    remove_layers_from_prefix(saimese.net_x, saimese.prefix_z);
    saimese.zFeatId = saimese.net_z.getVarIndex(saimese.id_feat_z);
    saimese.scoreId = saimese.net_x.getVarIndex(saimese.id_score);