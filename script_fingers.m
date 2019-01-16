%% TEAM 2: Counting number of fingers (from a complete body photo)

close all;
clear;

%Selecting the image to process

%for instance, you can test: "testi.jpg", with i = 1,2,...,7, which work
%well ; or "wtesti.jpg", with i = 1,2,3, wich work a bit less well (but
%not that far from well !)
name_photo=input('Enter your photo file name:','s'); 
ima=imread(name_photo);
orginal = ima;

%% Finding "skin" clusters in the image

colormap(gray(256));
hsv = rgb2hsv(ima);

%in order to do this, we use a combination of Hue (more precisely, 
%inversed Hue, which was easier to manipulate for me), and Saturation

saturation = hsv(:,:,2);
inv_hue = 255-hsv(:,:,1)*255;

%empirically, the treshold 235 appeared to be the best to select the hue
%zones corresponding to the skin: we create a binary image with this
%treshold

temp = inv_hue;
temp(temp<235)=uint8(0);
temp(temp>235)=uint8(255);

%we multiply, term by term, our binary image by the saturation matrix
%(empirically: higher the saturation is, the more likely we are to be on a 
%skin area)

temp = temp.*((saturation));

%we use a new treshold (empirically determined), in order to select only
%the most insteresting parts of the photo, which is made binary with:
%pixels = 255 on skin areas, and pixels = 0 everywhere else

temp(temp<40)=uint8(0);
temp(temp>40)=uint8(255);
temp = uint8(temp);

%% Then, we label the image and select the three biggest clusters
%%(assuming these clusters will always be: the head and the two hands,
%%which can be linked to arms)

labeledImage = bwlabel(temp);
measurements = regionprops(labeledImage, 'BoundingBox', 'Area');
for k = 1 : length(measurements)
    thisBB = measurements(k).BoundingBox;
    %rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
      %  'EdgeColor','r','LineWidth',2 )
end

% We extract the three biggest areas
allAreas = [measurements.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');
handIndex1 = sortingIndexes(1); 
handIndex2 = sortingIndexes(2); 
handIndex3 = sortingIndexes(3);

%We use ismember() to extact the hands and the head from the labeled image.
handImage1 = ismember(labeledImage, handIndex1);
handImage2 = ismember(labeledImage, handIndex2);
handImage3 = ismember(labeledImage, handIndex3);


%%We crop the two hands and the head from the image, and save their centroid's positions
bin = bwconvhull(handImage1, 'union');
region = regionprops(logical(bin), 'BoundingBox');
BoundingBox1 = region(1).BoundingBox;
poz1 = regionprops(logical(bin), 'Centroid');
cropped1 = imcrop(orginal, BoundingBox1);

bin2 = bwconvhull(handImage2, 'union');
region = regionprops(logical(bin2), 'BoundingBox');
BoundingBox2 = region(1).BoundingBox;
poz2 = regionprops(logical(bin2), 'Centroid');
cropped2 = imcrop(orginal, BoundingBox2);

bin3 = bwconvhull(handImage3, 'union');
region = regionprops(logical(bin3), 'BoundingBox');
BoundingBox3 = region(1).BoundingBox;
poz3 = regionprops(logical(bin3), 'Centroid');
cropped3 = imcrop(orginal, BoundingBox3);

all_cropped = cell(1,3);
all_cropped{1} = cropped1;
all_cropped{2} = cropped2;
all_cropped{3} = cropped3;

%We assume that there are always two hands shown on the image
two_hands_flag = true;

%And we select the two clusters of points of the extremities of the image,
%thanks to the centroids abscissa
%(always assuming that the head is at the center of the two hands)

x= [poz1.Centroid(1) poz2.Centroid(1) poz3.Centroid(1)];

[b, i] = sort(x, 'ascend');
hand_im1 = all_cropped{i(1)};
hand_im2 = all_cropped{i(3)};
%figure(1);
%image(hand_im1);
%figure(2);
%image(hand_im2);


%% Now that we have our two hands correctly cropped and selected,
%%let's count the number of fingers on each of them

sum_fingers=count_fingers(hand_im1);

disp(['The number of fingers in the first hand (right hand of the subject) is ',num2str(sum_fingers)]);

%In our case, we always consider that two_hands_flag = true, to simplify
if (two_hands_flag)
    sum_fingers=sum_fingers+count_fingers(hand_im2);
end

%And we print the sum of the numbers of fingers shown
disp(['The total number of fingers in both hands is ',num2str(sum_fingers)]);