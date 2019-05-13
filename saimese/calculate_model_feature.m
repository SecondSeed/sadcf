function [z_features, s_x, avgChans] = calculate_model_feature(cpu_im, pos, sz, p)

%    [imgFiles, targetPosition, targetSize] = load_video_info(p.seq_base_path, p.video);
%    nImgs = numel(imgFiles);
%    startFrame = 1;
    % Divide the net in 2
    % exemplar branch (used only once per video) computes features for the target
    im = gpuArray(single(cpu_im));
    % if grayscale repeat one channel to match filters size
    if(size(im, 3)==1)
        im = repmat(im, [1 1 3]);
    end
%     % Init visualization
%     videoPlayer = [];
%     if p.visualization && isToolboxAvailable('Computer Vision System Toolbox')
%         videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
%     end
    % get avg for padding
    avgChans = gather([mean(mean(im(:,:,1))) mean(mean(im(:,:,2))) mean(mean(im(:,:,3)))]);

    wc_z = sz(2) + p.contextAmount*sum(sz);
    hc_z = sz(1) + p.contextAmount*sum(sz);
    s_z = sqrt(wc_z*hc_z);
    scale_z = p.exemplarSize / s_z;
    % initialize the exemplar
    [z_crop, ~] = get_subwindow_tracking(im, pos, [p.exemplarSize p.exemplarSize], [round(s_z) round(s_z)], avgChans);
    if p.subMean
        z_crop = bsxfun(@minus, z_crop, reshape(stats.z.rgbMean, [1 1 3]));
    end
    d_search = (p.instanceSize - p.exemplarSize)/2;
    pad = d_search/scale_z;
    s_x = s_z + 2*pad;

%     scales = (p.scaleStep .^ ((ceil(p.numScale/2)-p.numScale) : floor(p.numScale/2)));
    % evaluate the offline-trained network for exemplar z features
    p.net_z.eval({'exemplar', z_crop});
    z_features = p.net_z.vars(p.zFeatId).value;
    z_features = repmat(z_features, [1 1 1 p.numScale]);

% 

