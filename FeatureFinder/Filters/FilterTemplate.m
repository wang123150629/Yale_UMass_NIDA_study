% FILTERED_DATA=FilterTemplate(DATA,FS)
%   This template will help you create your own filters!  Just follow 
%   instructions 1-3 below, and you'll be on your way.  (Note that you must
%   have at least some MATLAB programming experience in order to create
%   your own filters.)
%   
%   Input arguments:
%       DATA - The data to be filtered.
%       FS - The sampling rate of the data.
%
%   Output values:
%       FILTERED_DATA - The filtered data.  
%           
%        -- OR --
%       
%       FILTERED_DATA - The filter description.  This is outputted if the
%           function receives no input arguments. (not currently supported)
%          
%
% Written by Alex Andrews, 2011.


% GUIDE TO CREATING YOUR FILTER FUNCTION:
%
%   1) Select "File" --> "Save As..." and enter the filter name (e.g.,
%      "TotallyNewFilter.m").  You can also update "FilterTemplate" in the
%      function header below to the new name (optional).
function nFilteredData=FilterTemplate(nData,Fs)


%   2) Enter the filter description below, ensuring that it begins with a
%      single quote (') and ends with a single quote and semicolon (';).
%      (Watch that you don't edit any of the other three lines.)
%   NOTE:  This functionality is not currently supported (but entering the
%   description will do no harm regardless).
if nargin==0
    nFilteredData='Enter the filter description here!';        
    return
end


%   3) Write the code to filter the input data (nData), putting the
%   filtered data in the output variable (nFilteredData).
%   (This example performs a full-wave rectification.)
nFilteredData=abs(nData);