function candidate_exp = excuteCfDetection(candidate_exp, expert, im, pos, target_sz, p, bg_area,bg_hist, fg_hist, hann_window_cosine, area_resize_factor, w2c)
im_patch_cf = getSubwindow(im, pos, p.norm_bg_area, bg_area);

% color histogram (mask)
[likelihood_map] = getColourMap(im_patch_cf, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
likelihood_map(isnan(likelihood_map)) = 0;
likelihood_map = imResample(likelihood_map, p.cf_response_size);
% likelihood_map normalization, and avoid too many zero values
likelihood_map = (likelihood_map + min(likelihood_map(:)))/(max(likelihood_map(:)) + min(likelihood_map(:)));
if (sum(likelihood_map(:))/prod(p.cf_response_size)<0.01), likelihood_map = 1; end
likelihood_map = max(likelihood_map, 0.1);
% apply color mask to sample(or hann_window)
hann_window =  hann_window_cosine .* likelihood_map;
% compute feature map
[xt_CN, xt_HOG1, xt_HOG2] = getFeatureMap(im_patch_cf, p.cf_response_size, p.hog_cell_size, w2c);
% construct multiple experts
candidate_exp(1).xt = xt_CN;
candidate_exp(2).xt = xt_HOG1;
candidate_exp(3).xt = xt_HOG2;
candidate_exp(4).xt = cat(3 , xt_HOG1, xt_CN);
candidate_exp(5).xt = cat(3 , xt_HOG2, xt_CN);
candidate_exp(6).xt = cat(3 , xt_HOG1, xt_HOG2);
candidate_exp(7).xt = cat(3 , xt_HOG1, xt_HOG2, xt_CN);

for i = 1:p.cfExpertNum
    % apply Hann window
    xt_windowed = bsxfun(@times, hann_window, candidate_exp(i).xt);
    % compute FFT
    xtf = fft2(xt_windowed);
    % Correlation between filter and test patch gives the response
    hf = bsxfun(@rdivide, expert(i).hf_num, sum(expert(i).hf_den, 3) + p.lambda);
    response_cf = ensure_real(ifft2(sum( conj(hf) .* xtf, 3)));
    % Crop square search region (in feature pixels).
    response_cf = cropFilterResponse(response_cf, floor_odd(p.norm_delta_area / p.hog_cell_size));
    % Scale up to match center likelihood resolution.
    candidate_exp(i).response = mexResize(response_cf, p.norm_delta_area,'auto');
end


center = (1 + p.norm_delta_area) / 2;
for i = 1 : p.cfExpertNum
    candidate_exp(i).max_response = max(candidate_exp(i).response(:));
    [row, col] = find(candidate_exp(i).response == max(candidate_exp(i).response(:)), 1);
    candidate_exp(i).pos = pos + ([row, col] - center) / area_resize_factor;
    candidate_exp(i).rect_position = [candidate_exp(i).pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
    candidate_exp(i).center = [candidate_exp(i).rect_position(1) + (candidate_exp(i).rect_position(3)-1)/2  candidate_exp(i).rect_position(2) + (candidate_exp(i).rect_position(4)-1)/2];
end
end

% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
y = 2*floor((x-1) / 2) + 1;
end

function y = ensure_real(x)
assert(norm(imag(x(:))) <= 1e-5 * norm(real(x(:))));
y = real(x);
end