function slice = getSlice(im_sz, pos, sz)


%make sure the size is not to small
sz = max(sz, 2);
%if sz(1) < 1, sz(1) = 2; end;
%if sz(2) < 1, sz(2) = 2; end;

%xs = floor(pos(2)) + (1:sz(2)) - floor(sz(2)/2);
%ys = floor(pos(1)) + (1:sz(1)) - floor(sz(1)/2);
xs = round(pos(2) + (1:sz(2)) - sz(2)/2);
ys = round(pos(1) + (1:sz(1)) - sz(1)/2);

%check for out-of-bounds coordinates, and set them to the values at
%the borders
xs(xs < 1) = 1;
ys(ys < 1) = 1;
xs(xs > im_sz(2)) = im_sz(2);
ys(ys > im_sz(1)) = im_sz(1);

%extract image
slice.y = ys;
slice.x = xs;