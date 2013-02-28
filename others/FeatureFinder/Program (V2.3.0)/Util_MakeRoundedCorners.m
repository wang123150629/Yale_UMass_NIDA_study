% COORDS=Util_MakeRoundedCorners(X,Y,W,H,R,PLOT_W,PLOT_H,XLIM,YLIM)
%   This function calculates the coordinates required to make a rectangular
%   patch with rounded corners.  The coordinates are calculated so that the 
%   corner roundness will appear the same in the x and y directions if the 
%   x- and y-axis scales are different.  Corner radius is specified 
%   relative to the plot height.
%
%   Inputs:
%       X,Y,W,H - The position and size of the desired patch
%       R - The corner radius, relative to the plot height.  For example,
%           if R=0.05, then the corners would have widths and heights equal
%           to 5% of the plot height.
%       AXES_W,AXES_H - Axes width and height (pixels).
%       XLIM,YLIM - The x and y limits of the plot.
%
%   Outputs:
%       OUT_X, OUT_Y - The coordinates of a rectangular patch with rounded
%           corners.
%   
%   Written by Alexander J. Andrews, 2012.

function nPatch=Util_MakeRoundedCorners(x,y,w,h,r,...
    nAxesWidth,nAxesHeight,nXLim,nYLim)

% Ensure that corner radius isn't greater than half the intended width or
% height
Rp=r*nAxesHeight;
if (2*Rp)*diff(nXLim)/nAxesWidth>w
    Rp=floor(0.5*w*nAxesWidth/diff(nXLim));
elseif (2*Rp)*diff(nYLim)/nAxesHeight>h
    Rp=floor(0.5*h*nAxesHeight/diff(nYLim));
end

% Define angular spacing such that a) no two points are farther than a
% pixel apart, and b) that there will be points at 0?, 90?, etc.
dA=asin(1/Rp);
dA=pi/2/ceil((pi/2)/dA);

% -- Top left
nTL=fMakeUnitArc(pi,pi/2,dA);
nTL.X=(nTL.X+1)*Rp*diff(nXLim)/nAxesWidth+x;
nTL.Y=(nTL.Y-1)*Rp*diff(nYLim)/nAxesHeight+y+h;

% -- Top right
nTR=fMakeUnitArc(pi/2,0,dA);
nTR.X=(nTR.X-1)*Rp*diff(nXLim)/nAxesWidth+x+w;
nTR.Y=(nTR.Y-1)*Rp*diff(nYLim)/nAxesHeight+y+h;

% -- Bottom right
nBR=fMakeUnitArc(0,-pi/2,dA);
nBR.X=(nBR.X-1)*Rp*diff(nXLim)/nAxesWidth+x+w;
nBR.Y=(nBR.Y+1)*Rp*diff(nYLim)/nAxesHeight+y;

% -- Bottom left
nBL=fMakeUnitArc(-pi/2,-pi,dA);
nBL.X=(nBL.X+1)*Rp*diff(nXLim)/nAxesWidth+x;
nBL.Y=(nBL.Y+1)*Rp*diff(nYLim)/nAxesHeight+y;

% Construct patch (start with top left corner
nPatch.X=[nTL.X nTR.X nBR.X nBL.X];
nPatch.Y=[nTL.Y nTR.Y nBR.Y nBL.Y];


% This function creates an arc from A1 to A2 with spacing of dA radians
function nArc=fMakeUnitArc(A1,A2,dA)

if A1>A2
	A=A1:-dA:A2;
else
	A=A1:dA:A2;
end

nArc.X=cos(A);
nArc.Y=sin(A);
