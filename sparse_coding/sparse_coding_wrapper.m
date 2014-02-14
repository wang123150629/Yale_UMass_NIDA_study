function[varargout] = sparse_coding_wrapper(analysis_id, pipeline, varargin)

% sparse_coding_wrapper('140201a', 13)

close all;
plot_dir = get_project_settings('plots');

if nargin < 2, error('Missing analysis_id and/or pipeline information!'); end
assert(length(analysis_id) == 7);
if ~exist(fullfile(plot_dir, 'sparse_coding', analysis_id))
	mkdir(fullfile(plot_dir, 'sparse_coding', analysis_id));
end
assert(isnumeric(pipeline));

grnd_trth_subject_id = 'P20_040';
puwave_subject_id = 'P20_040_wqrs';
% grnd_trth_subject_id = 'sel100_atr';
% puwave_subject_id = 'sel100';
% grnd_trth_subject_id = '16773_atr';
% puwave_subject_id = '16773_wqrs';

lambda = 0.015;
give_it_some_slack = false;

from_wrapper = false;
partition_train_set = 1;
if length(varargin) > 0
	partition_train_set = varargin{1};
	from_wrapper = true;
end
matching_pm = 4;
if length(varargin) > 1
	matching_pm = varargin{2};
	from_wrapper = true;
end
first_baseline_subtract = true;
sparse_code_peaks = true;
normalize = -1;
add_height = -1;
variable_window = false;
add_summ_diff = false;
add_all_diff = false;

switch pipeline
	case 1, normalize = 1;
	case 2, normalize = 1; add_height = 1;
	case 3, normalize = 1; add_height = 2;
	case 4, normalize = 2; 
	case 5, normalize = 2; add_height = 1;
	case 6, normalize = 2; add_height = 2;
	case 7, normalize = 3;
	case 8, normalize = 3; add_height = 1;
	case 9, normalize = 3; add_height = 2;
	otherwise, error('Invalid pipeline!');
end

title_str = '';
if first_baseline_subtract, title_str = strcat(title_str, 'bl+'); end
if sparse_code_peaks, title_str = strcat(title_str, sprintf('sc(%0.4f)+', lambda)); end
switch normalize
case 1, title_str = strcat(title_str, 'snorm(w)+');
case 2, title_str = strcat(title_str, 'snorm+');
case 3, title_str = strcat(title_str, 'norm(p)+');
otherwise, error('Invalid normalize option!');
end
switch add_height
case 1, title_str = strcat(title_str, 'h+');
case 2, title_str = strcat(title_str, 'h^2+');
end
if variable_window, strcat(title_str, 'varwin+'); end
if add_summ_diff, strcat(title_str, 'summdiff+'); end
if add_all_diff, strcat(title_str, 'alldiff+'); end

switch partition_train_set
case 1, title_str = strcat(title_str, 'T');
case 2, title_str = strcat(title_str, 'R');
otherwise, error('Invalid train/test partition!');
end

[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat] = sparse_coding(first_baseline_subtract,...
			sparse_code_peaks, variable_window, normalize,...
			add_height, add_summ_diff,...
			add_all_diff, lambda, analysis_id, grnd_trth_subject_id, title_str,...
			partition_train_set, puwave_subject_id, matching_pm, from_wrapper, give_it_some_slack);

varargout{1} = mul_confusion_mat;
varargout{2} = matching_confusion_mat;
varargout{3} = crf_confusion_mat;

