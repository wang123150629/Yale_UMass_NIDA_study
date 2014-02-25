function[set1_alpha, set2_alpha, title_str, D] = setup_crf_feature(pipeline, partitioned_data, set1_str, set2_str, varargin)

lambda = 0.015;
nDictionayElements = 100;
nIterations = 1000;
add_height = -1;
normalize = -1;

title_str = '';
D = [];
switch length(varargin)
case 1, title_str = varargin{1};
case 2, title_str = varargin{1}; D = varargin{2};
end

switch pipeline
	case 1, normalize = 1;
	case 2, normalize = 1; add_height = 1;
	case 3, normalize = 1; add_height = 2;
	case 4, normalize = 3;
	case 5, normalize = 3; add_height = 1;
	case 6, normalize = 3; add_height = 2;
	%{
	% where I was dividing by the within peak std dev
	case 4, normalize = 2; 
	case 5, normalize = 2; add_height = 1;
	case 6, normalize = 2; add_height = 2;
	%}
	otherwise, error('Invalid pipeline!');
end

set1_ecg = getfield(partitioned_data, sprintf('%s_snormed', set1_str));
set1_std = getfield(partitioned_data, sprintf('%s_std', set1_str));
set1_hgt = getfield(partitioned_data, sprintf('%s_heights', set1_str));
set2_ecg = getfield(partitioned_data, sprintf('%s_snormed', set2_str));
set2_std = getfield(partitioned_data, sprintf('%s_std', set2_str));
set2_hgt = getfield(partitioned_data, sprintf('%s_heights', set2_str));
learn_ecg = getfield(partitioned_data, sprintf('learn_snormed'));
learn_std = getfield(partitioned_data, sprintf('learn_std'));
learn_hgt = getfield(partitioned_data, sprintf('learn_heights'));

switch normalize
case 2
	learn_ecg = bsxfun(@rdivide, learn_ecg, learn_std);
	set1_ecg = bsxfun(@rdivide, set1_ecg, set1_std);
	set2_ecg = bsxfun(@rdivide, set2_ecg, set2_std);
case 3
	learn_ecg = bsxfun(@rdivide, learn_ecg, partitioned_data.pooled_std);
	set1_ecg = bsxfun(@rdivide, set1_ecg, partitioned_data.pooled_std);
	set2_ecg = bsxfun(@rdivide, set2_ecg, partitioned_data.pooled_std);
end

param = struct();
param.K = nDictionayElements;  % learns a dictionary with 100 elements
param.iter = nIterations;  % let us see what happens after 1000 iterations
param.lambda = lambda;
param.numThreads = 4; % number of threads
param.batchsize = 400;
param.approx = 0;
param.verbose = false;
param.mode = 2;

if isempty(D)
	D = mexTrainDL(learn_ecg, param);
end

% learn_alpha = mexLasso(ecg_learn, D, param);
set1_alpha = mexLasso(set1_ecg, D, param);
set2_alpha = mexLasso(set2_ecg, D, param);

switch add_height
case -1
	set1_alpha = set1_alpha';
	set2_alpha = set2_alpha';
case 1
	set1_alpha = [set1_alpha; set1_hgt]';
	set2_alpha = [set2_alpha; set2_hgt]';
case 2
	set1_alpha = [set1_alpha; set1_hgt; set1_hgt.^2; ones(size(set1_hgt))]';
	set2_alpha = [set2_alpha; set2_hgt; set2_hgt.^2; ones(size(set2_hgt))]';
end

if ~isempty(title_str)
	switch normalize
	case 1, title_str = strcat(title_str, 'snorm+');
	case 2, title_str = strcat(title_str, 'snorm(w)+');
	case 3, title_str = strcat(title_str, 'snorm(p)+');
	otherwise, error('Invalid normalize option!');
	end
	switch add_height
	case 1, title_str = strcat(title_str, 'h');
	case 2, title_str = strcat(title_str, 'h^2');
	otherwise, title_str = title_str(1:end-1);
	end
	% if variable_window, strcat(title_str, 'varwin+'); end
	% if add_summ_diff, strcat(title_str, 'summdiff+'); end
	% if add_all_diff, strcat(title_str, 'alldiff+'); end
end

