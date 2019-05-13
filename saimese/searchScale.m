function sz = searchScale(im, pos, base_target_sz, scale_factor, scale_factors, scale_window, scale_model_sz, param, sf_den)
       im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor * scale_factors, scale_window, scale_model_sz, param.hog_scale_cell_size);
       xsf = fft(im_patch_scale,[],2);
       scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + param.lambda) ));
       recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
       %set the scale
       scale_factor = scale_factor * scale_factors(recovered_scale);

       if scale_factor < min_scale_factor
           scale_factor = min_scale_factor;
       elseif scale_factor > max_scale_factor
           scale_factor = max_scale_factor;
       end
       % use new scale to update bboxes for target, filter, bg and fg models
       sz = round(base_target_sz * scale_factor);