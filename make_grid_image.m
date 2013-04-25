function img = make_grid_image(X,xsize,ysize,gx,gy,c) 
%img=make_grid_image(X,xsize,ysize,gx,gy,c)
%
%Description: This function takes a collection of N images of size
%(xsize x ysize) stored as N xsize*ysize long row vectors in X and 
%creates a single image containing a (gx x gy) grid of (xsize x ysize) 
%images. gx*gy must be greater than or equal to N. The individual images 
%are separated from each other by a two-pixel border with intensity 
%specified by c. The output image img can be displayed using the 
%command: imagesc(img);colormap gray;
%
%img:   The output image grid 
%X:     Matrix with N images of size (xsize x ysize) stored as an xsize*ysize
%       long row vector in row-major format. The size of X is thus
%       Nx(xsize*ysize).
%xsize: The width of the individual images
%ysize: The height of the individual images
%gx:    The number of horizontal grid cells
%gy:    The number of vertical grid cells.
%c:     The image intensity of the border around the individual images (should
%       be between 0 and 1.


[N,D] = size(X);
if(xsize*ysize~=D); error('Second matrix dimension must match product of image dimensions!');end
gridsize=[gx,gy];

gap=2;
img = c*ones((xsize+gap)*gridsize(1)-gap,(ysize+gap)*gridsize(2)-gap);

for n=1:N
  [a,b]=ind2sub([gridsize(1),gridsize(2)],n);
  img((a-1)*(xsize+gap)+(1:xsize),(b-1)*(ysize+gap)+(1:ysize))=reshape(X(n,:),[xsize,ysize])';
end

tmp = c*ones(size(img,1)+4,size(img,2)+4);
tmp(3:end-2,3:end-2) = img;
img=tmp;
