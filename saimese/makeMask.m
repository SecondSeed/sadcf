function optic_im = makeMask(im, pos, optical_area)
    optic_im = zeros(size(im, 1), size(im, 2), 'uint8');
    optic_sub_im = getSubwindow(im, pos, optical_area);
    if size(optic_sub_im, 3) == 3
        optic_sub_im = rgb2gray(optic_sub_im);
    end
    sz = size(im);
    slice = getSlice(sz, pos, optical_area);
    optic_im(slice.y, slice.x, :) = optic_sub_im;