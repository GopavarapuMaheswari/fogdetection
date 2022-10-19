clc;
clear all;
close all;
[I,path]=uigetfile('*.*','select the source image');
str=strcat(path,I);
img1=imread(str);
[r,t]=Bounding_function(img1,4);
figure;
subplot(121);
imshow(img1)
title('input')
subplot(122);
imshow(r)
title('output')
