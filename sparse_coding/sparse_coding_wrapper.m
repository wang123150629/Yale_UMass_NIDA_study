function[varargout] = sparse_coding_wrapper(analysis_id, pipeline, varargin)

% sparse_coding_wrapper('140201a', 13)

if nargin < 2, error('Missing analysis_id and/or pipeline information!'); end
assert(length(analysis_id) == 7);
assert(isnumeric(pipeline));
close all;

plot_dir = get_project_settings('plots');

lambda = 0.015;
grnd_trth_subject_id = 'P20_040';
puwave_subject_id = 'P20_040_wqrs';
% grnd_trth_subject_id = 'sel100_atr';
% puwave_subject_id = 'sel100';
% grnd_trth_subject_id = '16773_atr';
% puwave_subject_id = '16773_wqrs';

first_baseline_subtract = true;
sparse_code_peaks = true;
partition_train_set = 1;
from_wrapper = false;
if length(varargin) > 0
	partition_train_set = varargin{1};
	from_wrapper = true;
end
matching_pm = 4;
if length(varargin) > 1
	matching_pm = varargin{2};
	from_wrapper = true;
end
data_split = 'two_prt';
variable_window = false;
normalize = -1;
add_height = -1;
add_summ_diff = false;
add_all_diff = false;
give_it_some_slack = false;

switch pipeline
case 13
	normalize = 1;
	title_str = 'bl+sparse+norm';
case 14
	normalize = 1;
	add_height = 1;
	title_str = 'bl+sparse+norm+hgt';
case 15
	normalize = 1;
	add_height = 2;
	title_str = 'bl+sparse+norm+hgt^2';
case 16
	normalize = 2;
	title_str = 'bl+sparse+snorm';
case 17
	normalize = 2;
	add_height = 1;
	title_str = 'bl+sparse+snorm+hgt';
case 18
	normalize = 2;
	add_height = 2;
	title_str = 'bl+sparse+snorm+hgt^2';
case 19
	normalize = 3;
	title_str = 'bl+sparse+snorm(p)';
case 20
	normalize = 3;
	add_height = 1;
	title_str = 'bl+sparse+snorm(p)+hgt';
case 21
	normalize = 3;
	add_height = 2;
	title_str = 'bl+sparse+snorm(p)+hgt^2';
otherwise, error('Invalid pipeline!');
end

switch partition_train_set
case 1, title_str = strcat(title_str, '+T');
case 2, title_str = strcat(title_str, '+R');
otherwise, error('Invalid train/test partition!');
end

if ~exist(fullfile(plot_dir, 'sparse_coding', analysis_id))
	mkdir(fullfile(plot_dir, 'sparse_coding', analysis_id));
end

[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat] = sparse_coding(first_baseline_subtract,...
			sparse_code_peaks, variable_window, normalize,...
			add_height, add_summ_diff,...
			add_all_diff, lambda, analysis_id, grnd_trth_subject_id, title_str, data_split,...
			partition_train_set, puwave_subject_id, matching_pm, from_wrapper, give_it_some_slack);

varargout{1} = mul_confusion_mat;
varargout{2} = matching_confusion_mat;
varargout{3} = crf_confusion_mat;

%{
case 1
	sparse_code_peaks = true;
	title_str = 'sparse';
case 2
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	title_str = 'bl+sparse';
case 3
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	title_str = 'bl+sparse+var';
case 4
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	normalize = 1;
	title_str = 'bl+sparse+var+norm';
case 5
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	normalize = 1;
	add_height = 1;
	title_str = 'bl+sparse+var+norm+hgt';
case 6
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	normalize = 1;
	add_height = 1;
	add_summ_diff = true;
	title_str = 'bl+sparse+var+norm+hgt+summ diff';
case 7
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	normalize = 1;
	add_height = 1;
	add_all_diff = true;
	title_str = 'bl+sparse+var+norm+hgt+all diff';
case 8
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	add_summ_diff = true;
	title_str = 'bl+sparse+summ diff';
case 9
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	variable_window = true;
	add_all_diff = true;
	title_str = 'bl+sparse+var+all diff';
case 10
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	add_summ_diff = true;
	title_str = 'bl+sparse+norm+summ diff';
case 11
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	add_all_diff = true;
	title_str = 'bl+sparse+norm+all diff';
case 12
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	title_str = 'bl+sparse+norm';
%}
