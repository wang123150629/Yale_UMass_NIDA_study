function[varargout] = label_ecg_peaks_wrapper(analysis_id, subject_id, varargin)

% label_ecg_peaks_wrapper('dummyyy', 'P20_040');
% label_ecg_peaks_wrapper('dummyyy', '16773_atr');

close all;
plot_dir = get_project_settings('plots');

if nargin < 1, error('Missing analysis_id!'); end
assert(length(analysis_id) >= 7);
if ~exist(fullfile(plot_dir, 'sparse_coding', analysis_id))
	mkdir(fullfile(plot_dir, 'sparse_coding', analysis_id));
end

% use_multiple_u_labels = '';
% use_multiple_u_labels = 'interintra';
use_multiple_u_labels = 'qrsonly';
give_it_some_slack = false;
first_baseline_subtract = true;

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

[mul_confusion_mat, matching_confusion_mat, crf_confusion_mat,...
		crf_validate_errors, mul_validate_errors] = label_ecg_peaks(analysis_id, subject_id,...
								first_baseline_subtract, partition_train_set,...
								give_it_some_slack, matching_pm, from_wrapper,...
								use_multiple_u_labels);
varargout{1} = mul_confusion_mat;
varargout{2} = matching_confusion_mat;
varargout{3} = crf_confusion_mat;
varargout{4} = crf_validate_errors;
varargout{5} = mul_validate_errors;

