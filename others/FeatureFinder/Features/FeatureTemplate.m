% FEATURE=FeatureTemplate(DATA,FS,BL,TARGET)
%   This template will help you create your own features!  Just follow 
%   instructions 1-4 below, and you'll be on your way.  (Note that you must
%   have at least some MATLAB programming experience in order to create
%   your own features.)
%   
%   Input arguments:
%       DATA - The data from which you'll extract a single feature.
%       FS - The sampling rate of the data.
%       BL - The samples associated with the baseline window.
%       TARGET - The samples associated with the target window.
%
%   Output values:
%       FEATURE - The calculated feature.  It must be scalar (e.g., 
%           1.2 is OK, but [2 4 3] isn't) and numeric (e.g., not 'mouse').
%           
%        -- OR --
%       
%       FEATURE - The feature description.  This is outputted if the
%           function receives no input arguments.
%          
%
% Written by Alex Andrews, 2011.


% GUIDE TO CREATING YOUR FEATURE FUNCTION:
%
%   1) Select "File" --> "Save As..." and enter the feature name (e.g.,
%      "BrandNewFeature.m").  You can also update "FeatureTemplate" in the
%      function header below to the new name (optional).
function nFeature=FeatureTemplate(nData,Fs,nBL_Range,nTarg_Range)


%   2) Enter the feature description below, ensuring that it begins with a
%      single quote (') and ends with a single quote and semicolon (';).
%      (Watch that you don't edit any of the other three lines.)
if nargin==0
    nFeature='Enter the feature description here!';        
    return
end


%   3) Write the code to calculate your feature. Remember that nTarg_Range
%   and nBL_Range contain the sample numbers corresponding to the target
%   and baseline windows.  That said, use of this information is optional.
%   (This example calculates the difference between window averages.)
nTarg_Amp=mean(nData(nTarg_Range));        
nBL_Amp=mean(nData(nBL_Range));


%   4)  Put the feature value in the nFeature variable
%   (This example calculates the difference between window averages.)
nFeature=nTarg_Amp-nBL_Amp;