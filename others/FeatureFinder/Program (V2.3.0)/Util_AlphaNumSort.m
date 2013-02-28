% [SORTED INDICES]=Util_AlphaNumSort(UNSORTED)
%   This function sorts the strings in UNSORTED using numeric sorting for
%   numeric values and alphabetic sorting for alphabetic values.  This way,
%   sorting errors such as [1 10 2 3 4 ...] can be avoided.
%   
%   Input arguments:
%       UNSORTED - the list of values to be sorted (cell array of strings)
%       INDICES - sorting order of input, such that SORTED=UNSORTED(INDICES) 
%       
%   Output arguments;
%       SORTED - the sorted values
%
% Written by Alex Andrews, 2010-2011.

function [cSorted nSorted]=Util_AlphaNumSort(cUnsorted)

% Convert cUnsorted to column vector
if size(cUnsorted,2)>1
    cUnsorted=cUnsorted';
end

% Separate blank, numeric, and non-numeric entries
nBlank=cellfun(@isempty,cUnsorted);
cBlank=cUnsorted(nBlank);
nAlpha=isnan(str2double(cUnsorted))&~nBlank;
cAlpha=cUnsorted(nAlpha);
nNum=find(ones(length(cUnsorted),1)&(1-nAlpha)&(1-nBlank));
cNum=cUnsorted(nNum);
nAlpha=find(nAlpha);

% Sort each group
nSortedBlank=find(nBlank);
[cAlpha nSortedAlpha]=sort(cAlpha);
nSortedAlpha=nAlpha(nSortedAlpha);
[temp nSortedNum]=sort(str2double(cNum));
cNum=cNum(nSortedNum);
nSortedNum=nNum(nSortedNum);

% Reconstruct group
cSorted=[cNum;cAlpha;cBlank];
nSorted=[nSortedNum;nSortedAlpha;nSortedBlank];