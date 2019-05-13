videoname = 'Basketball'; 
img_path = 'sequence/Basketball/img/';
base_path = 'sequence/';
[img_files, pos, target_sz, video_path] = load_video_info(base_path, videoname);

opticFlow = opticalFlowLK('NoiseThreshold', 0.009);

num_frame = numel(img_files);
for frame = 1:num_frame
    frameRGB = imread([img_path img_files{frame}]);
   frameGray = rgb2gray(frameRGB);
   flow = estimateFlow(opticFlow, frameGray);
   
   imshow(frameRGB)
   hold on
   plot(flow, 'DecimationFactor', [5 5], 'ScaleFactor', 10)
   drawnow
end

% function out = getOpticalFlow(img, pos, target_sz)
% 
% %RGBͼת�ɻҶ�ͼ
% if numel(img) > 2
%     img = rgb2gray(img)
% end
% 
% opticFlow = opticalFlowLK('NoiseThreshold', 0.009);


