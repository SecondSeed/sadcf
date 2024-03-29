function [results] = trackerMain(p, im, bg_area, fg_area, area_resize_factor, saimese)

% w2c: ColorName feature
temp = load('w2crs');
w2c = temp.w2crs;
pos = p.init_pos;
target_sz = p.target_sz;
period = p.period;
update_thres = p.update_thres;
learning_rate_pwp = p.lr_pwp_init;
learning_rate_cf = p.lr_cf_init;
weight_num = 0 : period-1;
weight = (1.1).^(weight_num);
expertNum = p.expertNum;
cfExpertNum = p.cfExpertNum;
num_frames = numel(p.img_files);
meanScore(1, num_frames) = 0;
PSRScore(1, num_frames) = 0;
IDensemble(1, expertNum) = 0;
output_rect_positions(num_frames, 4) = 0;
all_expert_pos(num_frames,7,4) = 0;
allSim = 0;
meanFirstSim = 0;
spacethreshold = saimese.spacethreshold;
scoreparam = saimese.scoreparam;
chooseSimExp = 0;
expand_threshold = saimese.up;

% patch of the target + padding
patch_padded = getSubwindow(im, pos, p.norm_bg_area, bg_area);
% initialize hist model
new_pwp_model = true;
[bg_hist, fg_hist] = updateHistModel(new_pwp_model, patch_padded, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, p.grayscale_sequence);
new_pwp_model = false;
% Hann (cosine) window
hann_window_cosine = single(hann(p.cf_response_size(1)) * hann(p.cf_response_size(2))');
% gaussian-shaped desired response, centred in (1,1)
% bandwidth proportional to target size
output_sigma = sqrt(prod(p.norm_target_sz)) * p.output_sigma_factor / p.hog_cell_size;
y = gaussianResponse(p.cf_response_size, output_sigma);
yf = fft2(y);

%% SCALE ADAPTATION INITIALIZATION
% Code from DSST
scale_factor = 1;
base_target_sz = target_sz;
scale_sigma = sqrt(p.num_scales) * p.scale_sigma_factor;
ss = (1:p.num_scales) - ceil(p.num_scales/2);
ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
ysf = single(fft(ys));
if mod(p.num_scales,2) == 0
    scale_window = single(hann(p.num_scales+1));
    scale_window = scale_window(2:end);
else
    scale_window = single(hann(p.num_scales));
end
ss = 1:p.num_scales;
scale_factors = p.scale_step.^(ceil(p.num_scales/2) - ss);
if p.scale_model_factor^2 * prod(p.norm_target_sz) > p.scale_model_max_area
    p.scale_model_factor = sqrt(p.scale_model_max_area/prod(p.norm_target_sz));
end
scale_model_sz = floor(p.norm_target_sz * p.scale_model_factor);
% find maximum and minimum scales
min_scale_factor = p.scale_step ^ ceil(log(max(5 ./ bg_area)) / log(p.scale_step));
max_scale_factor = p.scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ target_sz)) / log(p.scale_step));

% Main Loop
tic;
t_imread = 0;
for frame = 1:num_frames
    if frame>1
        tic_imread = tic;
        im = imread([p.img_path p.img_files{frame}]);
        t_imread = t_imread + toc(tic_imread);
        
        [saimeseExp, expand_threshold] = expandSpace(saimeseExp, im, pos, target_sz, first_feature, saimese, s_x, avgChans, meanFirstSim, expand_threshold);

        origin_exp = excuteCfDetection(origin_exp, expert, im, pos, target_sz, p, bg_area,bg_hist, fg_hist, hann_window_cosine, area_resize_factor, w2c);
        is_expand = 0;
        if saimeseExp.expand == 1
            expand_exp = excuteCfDetection(expand_exp, expert, im, saimeseExp.pos, target_sz, p, bg_area,bg_hist, fg_hist, hann_window_cosine, area_resize_factor, w2c);
            [finalExp, is_expand] = chooseCfExp(origin_exp, expand_exp, saimeseExp, spacethreshold, scoreparam);
        else
            finalExp = origin_exp;
        end
        if is_expand == 1 && saimeseExp.chooseExpandPos == 1
            finalExp = calculateCfSimilarity(finalExp, saimeseExp.pos, saimeseExp.expand_response, s_x, saimese);
        else
            finalExp = calculateCfSimilarity(finalExp, pos, saimeseExp.response, s_x, saimese);
        end
        expert = mergeExpert(expert, finalExp, saimeseExp, frame, p);
        for i = 1 :7
            all_expert_pos(frame,i,1:2) = finalExp(i).pos; 
            all_expert_pos(frame,i,3:4) = target_sz;
        end
        
        
        
        
        % 使用 meanFirstSim 来将相似性分数映射到 0 - 1 之间，
        % 并对 expert 增加 hold 字段， 使相似性分数低于平均值的专家hold字段置false
%         expert = calculateRelativeSimilarity(expert, expertNum, meanFirstSim, 0, frame, holdparam);
    if frame > period - 1
        for i = 1 : expertNum
            % expert robustness evaluation
            expert(i).RobScore = RobustnessEva(expert, i, frame, period, weight, expertNum);
            IDensemble(i) = expert(i).RobScore;
        end
        % 将鲁棒性分数归一化
        %             expert = normRobust(expert, expertNum);
        meanScore(frame) = sum(IDensemble)/expertNum;
        [~, ID] = sort(IDensemble, 'descend');
        pos = expert( ID(1) ).pos;
        Final_rect_position = expert( ID(1) ).rect_position(frame,:);
        max_sim = expert(ID(1)).fsim;
        allSim = allSim + max_sim;
        if ID(1) == p.simId
            chooseSimExp = 1;
        else
            chooseSimExp = 0;
        end
    else
        for i = 1:expertNum,  expert(i).RobScore(frame) = 1;  end
        pos = expert(7).pos;
        Final_rect_position = expert(7).rect_position(frame,:);
        max_sim = expert(7).fsim;
        allSim = allSim + max_sim;
    end


        meanFirstSim = allSim / (frame - 1);
        
        %% ADAPTIVE UPDATE
        Score1 = calculatePSR(finalExp(1).response);
        Score2 = calculatePSR(finalExp(2).response);
        Score3 = calculatePSR(finalExp(3).response);
        PSRScore(frame) = (Score1 + Score2 + Score3)/3;
        
        if frame > period - 1
            FinalScore = meanScore(frame)*PSRScore(frame);
            AveScore = sum(meanScore(period:frame).*PSRScore(period:frame))/(frame - period + 1);
            threshold =  update_thres * AveScore;
            if  FinalScore > threshold
                learning_rate_pwp = p.lr_pwp_init;
                learning_rate_cf = p.lr_cf_init;
            else
                % disp( [num2str(frame),'th Frame. Adaptive Update.']);
                % for color mask, just discard unreliable sample
                learning_rate_pwp = 0;
                % for DCF model, penalize the sample with low score
                learning_rate_cf = (FinalScore/threshold)^3 * p.lr_cf_init;
            end
        end
        
        %% SCALE SPACE SEARCH
        if chooseSimExp == 0
            im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor * scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
            xsf = fft(im_patch_scale,[],2);
            scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + p.lambda) ));
            recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
            %set the scale
            scale_factor = scale_factor * scale_factors(recovered_scale);
            
            if scale_factor < min_scale_factor
                scale_factor = min_scale_factor;
            elseif scale_factor > max_scale_factor
                scale_factor = max_scale_factor;
            end
        else
            scale_factor = saimeseExp.sz / base_target_sz;
            if scale_factor < min_scale_factor
                scale_factor = min_scale_factor;
            elseif scale_factor > max_scale_factor
                scale_factor = max_scale_factor;
            end
        end
        
        % use new scale to update bboxes for target, filter, bg and fg models
        target_sz = round(base_target_sz * scale_factor);
        p.avg_dim = sum(target_sz)/2;
        bg_area = round(target_sz + p.avg_dim * p.padding);
        if(bg_area(2)>size(im,2)),  bg_area(2)=size(im,2)-1;    end
        if(bg_area(1)>size(im,1)),  bg_area(1)=size(im,1)-1;    end
        
        bg_area = bg_area - mod(bg_area - target_sz, 2);
        fg_area = round(target_sz - p.avg_dim * p.inner_padding);
        fg_area = fg_area + mod(bg_area - fg_area, 2);
        % Compute the rectangle with (or close to) params.fixed_area and same aspect ratio as the target bboxgetScaleSubwindow
        area_resize_factor = sqrt(p.fixed_area/prod(bg_area));
    end    
        
        % extract patch of size bg_area and resize to norm_bg_area
        im_patch_bg = getSubwindow(im, pos, p.norm_bg_area, bg_area);
        % compute feature map, of cf_response_size
        [xt_CN, xt_HOG1, xt_HOG2] = getFeatureMap(im_patch_bg, p.cf_response_size, p.hog_cell_size, w2c);
        
        expert(1).xt = xt_CN;
        expert(2).xt = xt_HOG1;
        expert(3).xt = xt_HOG2;
        expert(4).xt = cat(3 , xt_HOG1, xt_CN);
        expert(5).xt = cat(3 , xt_HOG2, xt_CN);
        expert(6).xt = cat(3 , xt_HOG1, xt_HOG2);
        expert(7).xt = cat(3 , xt_HOG1, xt_HOG2, xt_CN);

        for i = 1:cfExpertNum
            % apply Hann window
            xt = bsxfun(@times, hann_window_cosine, expert(i).xt);
            % compute FFT
            xtf = fft2(xt);
            % FILTER UPDATE
            % Compute expectations over circular shifts, therefore divide by number of pixels.
            expert(i).new_hf_num = bsxfun(@times, conj(yf), xtf) / prod(p.cf_response_size);
            expert(i).new_hf_den = (conj(xtf) .* xtf) / prod(p.cf_response_size);
        end
   
        if frame == 1
            % first frame, train with a single image
            for i = 1 : cfExpertNum
                expert(i).hf_den = expert(i).new_hf_den;
                expert(i).hf_num = expert(i).new_hf_num;
            end
            
            % extract features from first frame
            [first_feature, base_s_x, avgChans] = calculate_model_feature(im, pos, target_sz, saimese);
            % first frame initialize optical flow model
        else
            for i = 1 : cfExpertNum
                % subsequent frames, update the model by linear interpolation
                expert(i).hf_den = (1 - learning_rate_cf) * expert(i).hf_den + learning_rate_cf * expert(i).new_hf_den;
                expert(i).hf_num = (1 - learning_rate_cf) * expert(i).hf_num + learning_rate_cf * expert(i).new_hf_num;
            end
            if learning_rate_pwp ~= 0
                % BG/FG MODEL UPDATE   patch of the target + padding
                im_patch_color = getSubwindow(im, pos, p.norm_bg_area, bg_area*(1-p.inner_padding));
                [bg_hist, fg_hist] = updateHistModel(new_pwp_model, im_patch_color, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, p.grayscale_sequence, bg_hist, fg_hist, learning_rate_pwp);
            end
        end
        
        %% SCALE UPDATE
        im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor*scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
        xsf = fft(im_patch_scale,[],2);
        new_sf_num = bsxfun(@times, ysf, conj(xsf));
        new_sf_den = sum(xsf .* conj(xsf), 1);
        s_x = scale_factor * base_s_x;
        if frame == 1
            sf_den = new_sf_den;
            sf_num = new_sf_num;
        else
            sf_den = (1 - p.learning_rate_scale) * sf_den + p.learning_rate_scale * new_sf_den;
            sf_num = (1 - p.learning_rate_scale) * sf_num + p.learning_rate_scale * new_sf_num;
        end
        % update bbox position
        if (frame == 1)
            Final_rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
            for i = 1:expertNum
                expert(i).rect_position(frame,:) = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
                expert(i).RobScore(frame) = 1;
                expert(i).center(frame,:) = [expert(i).rect_position(frame,1)+(expert(i).rect_position(frame,3)-1)/2 expert(i).rect_position(frame,2)+(expert(i).rect_position(frame,4)-1)/2];
                expert(i).smooth(frame) = 0;
                expert(i).smoothScore(frame) = 1;
                expert(i).hold(frame,:) = 1;
                expert(i).response = [];
                expert(i).flowscore = 0;
            end
            saimeseExp = initialSaimeseExp(pos, target_sz);
            origin_exp = [];
            expand_exp = [];
        end
        output_rect_positions(frame,:) = Final_rect_position;
        
        %% VISUALIZATION
        if p.visualization == 1
            if isToolboxAvailable('Computer Vision System Toolbox')
                %%% multi-expert result
%                 im = insertShape(im, 'Rectangle', expert(1).rect_position(frame,:), 'LineWidth', 3, 'Color', 'yellow');
%                 im = insertShape(im, 'Rectangle', expert(2).rect_position(frame,:), 'LineWidth', 3, 'Color', 'black');
%                 im = insertShape(im, 'Rectangle', expert(3).rect_position(frame,:), 'LineWidth', 3, 'Color', 'yellow');
%                 im = insertShape(im, 'Rectangle', expert(4).rect_position(frame,:), 'LineWidth', 3, 'Color', 'magenta');
%                 im = insertShape(im, 'Rectangle', expert(5).rect_position(frame,:), 'LineWidth', 3, 'Color', 'cyan');
%                 im = insertShape(im, 'Rectangle', expert(6).rect_position(frame,:), 'LineWidth', 3, 'Color', 'green');
%                 im = insertShape(im, 'Rectangle', expert(7).rect_position(frame,:), 'LineWidth', 3, 'Color', 'green');
%                 im = insertShape(im, 'Rectangle', expert(8).rect_position(frame,:), 'LineWidth', 3, 'Color', 'blue');
%                 %%% final result
                im = insertShape(im, 'Rectangle', Final_rect_position, 'LineWidth', 3, 'Color', 'red');
%                 % Display the annotated video frame using the video player object.

                imshow(im);


            else
                figure(1)
                imshow(uint8(im),'border','tight');
                text(5, 18, strcat('#',num2str(frame)), 'Color','y', 'FontWeight','bold', 'FontSize',30);
                % rectangle('Position',expert(1).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','y');
                % rectangle('Position',expert(2).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','c');
                % rectangle('Position',expert(3).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','b');
                % rectangle('Position',expert(4).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','m');
                % rectangle('Position',expert(5).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','k');
                % rectangle('Position',expert(6).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','g');
                % rectangle('Position',expert(7).rect_position(frame,:), 'LineWidth',2, 'LineStyle','-','EdgeColor','r');
                rectangle('Position',Final_rect_position, 'LineWidth',3, 'LineStyle','-','EdgeColor','r');
                drawnow
            end
        end
        
    
    elapsed_time = toc;
    % save result
    results.type = 'rect';
    results.res = output_rect_positions;
    results.pos = all_expert_pos;
    results.fps = num_frames/(elapsed_time - t_imread);
    
end
end


function PSR = calculatePSR(response_cf)
cf_max = max(response_cf(:));
cf_average = mean(response_cf(:));
cf_sigma = sqrt(var(response_cf(:)));
PSR = (cf_max - cf_average)/cf_sigma;
end
