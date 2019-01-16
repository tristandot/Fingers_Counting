function fingers=count_fingers(image)

im_hand=image;

%None of the RGB features seems adapted to binarize the hand image

%figure
%subplot(131)
%imshow(im_hand(:,:,1));
%title('Red')
%subplot(132)
%imshow(im_hand(:,:,2));
%title('Green')
%subplot(133)
%imshow(im_hand(:,:,3));
%title('Blue')

%%Consequently, we use the HSV space to binarize our cropped image of hand (+ arm,
%%eventually)
im_hand_hsv= rgb2hsv(im_hand);


%In the HSV Space, the Saturation Feature appears to be the most adapted to
%select skin areas

%figure
%subplot(131)
%imshow(im_hand_hsv(:,:,1));
%title('Hue')
%subplot(132)
%imshow(im_hand_hsv(:,:,2));
%title('Saturation')
%subplot(133)
%imshow(im_hand_hsv(:,:,3));
%title('Gray value')



%% Consequently, we apply kmeans (with two classes) on the saturation value
%%(in order to find the adapted treshold to binarize the image)

nb_classes=2;

%Selection of the two firts class centers
m1=0.3;
m2=0.7;

m=[m1 m2];

m_=[1 1];

%We work on a normalized image
im_h=double(im_hand_hsv(:,:,2)/max(max(im_hand_hsv(:,:,2))));

% loop on the class centers
while m ~= m_

  %classification of the pixels in the classes
  dist1_km=(im_h-m(1)).^2;
  dist2_km=(im_h-m(2)).^2;
  
  etiq_km = (dist1_km<=dist2_km)*1 + ...
          (dist2_km<dist1_km)*2 ;
%figure ; imshow(etiq_km) ; 
colormap(cool) ; pause(0.5) ;

   %updating of the class centers
   m_ = m ;
   m(1) = sum(sum((etiq_km==1).*im_h))./sum(sum(etiq_km==1)) ;
   m(2) = sum(sum((etiq_km==2).*im_h))./sum(sum(etiq_km==2)) ;
   
   
end

%We binarize the final, classified image
im_hand_binary=zeros(size(im_h));
im_hand_binary(etiq_km==2)=255;
%figure
%imshow(im_hand_binary);


%% Find extrem values of hand, in order to adjust the image just to the hand
im=im_hand_binary;
[x,y]=find(im==255);
xmin=min(x);
xmax=max(x);
ymin=min(y);
ymax=max(y);
im_adjusted=im(xmin:xmax,ymin:ymax);
%figure
%imshow(im_adjusted);

%Resizing of the image, to always work on same-sized photos, which will
%largely facilitate the next steps of mathematical morphology filtering
im_adjusted=uint8(imresize(im_adjusted,[256,256]));


%% Defining SE sizes (used for different mathematical morphology operations)
%Those sizes are empirical, and have been adjusted manually, on a lot of
%examples (approximately 20)
size_se1=4;
size_se2=32;
size_se3=9;
size_se4=8;

%If we have a photo of hand + arm (if there are twice more background
%pixels than white pixels: arbitrary criterium), we divise by 3 all the
%structuring elements sizes (in order to select smaller elements: fingers
%are smaller on the image when an arm is also present on it)
if (sum(sum(im_adjusted==0))>2*(sum(sum(im_adjusted==255))))
    size_se1=ceil(size_se1/3);
    size_se2=ceil(size_se2/3);
    size_se3=ceil(size_se3/3)+1;
end


%% First we apply a closing, to reduce the small "dark" noise there is on
%%the images
se=strel('disk',size_se1);
im_adjusted=imclose(im_adjusted,se);
im_adjusted(im_adjusted<128)=0;
im_adjusted(im_adjusted>=128)=255;
%figure
%imshow(im_adjusted);


%% Then a TopHat, with a structuring element adapted to the fingers (to the size
%%, and the morphology, of the fingers)
se=strel('disk',size_se2);
im_adjusted_op=imopen(im_adjusted,se);
im_fingers=imsubtract(im_adjusted,uint8(im_adjusted_op));
im_fingers(im_fingers<128)=0;
im_fingers(im_fingers>=128)=255;

%figure
%imshow(im_fingers);

%title('im_fingers before opening');


%% Then a final opening, to make disappear small clusters which shouldn't have been kept
se=strel('disk',size_se3);
im_fingers_op=imopen(uint8(im_fingers),se);
%figure
%imshow(im_fingers_op);

%Finally, we cut the bottom of the image, where there are often some
%small clusters of points, which cannot usually correspond to fingers
%(very empirical trick, but useful)
im_fingers_op_cut=im_fingers_op(1:180,1:end);
figure
imshow(im_fingers_op_cut);


%% Output result: counting the number of fingers thanks to bwlabel()
[~,fingers]=bwlabel(im_fingers_op_cut);

%Small trick: to reduce the too high number of clusters that we have,
%sometimes ; not very useful, but though...
fingers=min(fingers,5);
end