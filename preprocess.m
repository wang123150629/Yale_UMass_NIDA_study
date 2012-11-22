function[preprocessed_data] = preproces(raw_data)

% Checks if the correct number of arguments are passed in
if nargin < 1, error('Missing input parameters'); end

% Checks if the data matrix has blah columns
nCols = size(raw_data, 2);
if nCols ~= 40
	error('Incorrect number of columns (%d) in the input matrix!', nCols);
end

feature_ranges = [




];
