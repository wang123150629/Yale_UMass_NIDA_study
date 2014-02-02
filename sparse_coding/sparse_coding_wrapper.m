function[] = sparse_coding_wrapper(analysis_id, pipeline)

% sparse_coding_wrapper('140201a', 13)

if nargin ~= 2, error('Missing analysis_id and/or pipeline information!'); end
assert(length(analysis_id) == 7);
assert(isnumeric(pipeline));
close all;

plot_dir = get_project_settings('plots');

lambda = 0.015;
subject_id = 'P20_040';

first_baseline_subtract = false;
sparse_code_peaks = false;
variable_window = false;
normalize = -1;
add_height = -1;
add_summ_diff = false;
add_all_diff = false;
data_split = 'unf_spt';
partition_train_set = -1;

switch pipeline
case 13
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	data_split = 'two_prt';
	title_str = 'bl+sparse+norm';
case 14
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	add_height = 1;
	data_split = 'two_prt';
	title_str = 'bl+sparse+norm+hgt';
case 15
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 2;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm';
case 16
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 2;
	add_height = 1;
	partition_train_set = 1;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm+hgt+T';
case 17
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 2;
	add_height = 2;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm+hgt^2';
case 18
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 1;
	add_height = 2;
	data_split = 'two_prt';
	title_str = 'bl+sparse+norm+hgt^2';
case 19
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 3;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm';
case 20
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 3;
	add_height = 1;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm+hgt';
case 21
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 3;
	add_height = 2;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm+hgt^2';
case 22
	first_baseline_subtract = true;
	sparse_code_peaks = true;
	normalize = 2;
	add_height = 1;
	partition_train_set = 2;
	data_split = 'two_prt';
	title_str = 'bl+sparse+snorm+hgt+R';
otherwise, error('Invalid pipeline!');
end

if ~exist(fullfile(plot_dir, 'sparse_coding', analysis_id))
	mkdir(fullfile(plot_dir, 'sparse_coding', analysis_id));
end

sparse_coding(first_baseline_subtract, sparse_code_peaks, variable_window, normalize, add_height, add_summ_diff,...
			add_all_diff, lambda, analysis_id, subject_id, title_str, data_split, partition_train_set);

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
