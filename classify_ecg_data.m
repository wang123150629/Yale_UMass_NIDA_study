function[mean_over_runs, errorbars_over_runs, title_str, class_label, chance_baseline] =...
			classify_ecg_data(subject_id, classes_to_classify, set_of_features_to_try, nRuns, tr_percent, classifierList)

nFeatures = length(set_of_features_to_try);
nClassifiers = numel(classifierList);
nAnalysis = length(classes_to_classify);
if nargin < 6, error('Missing input arguments!'); end
assert(nAnalysis == 2);

loaded_data = [];
class_label = cell(1, nAnalysis);
title_str = cell(1, nFeatures);
chance_baseline = NaN(nFeatures, nRuns);
mean_over_runs = NaN(nFeatures, nClassifiers);
errorbars_over_runs = NaN(nFeatures, nClassifiers);

for c = 1:nAnalysis
	loaded_data = [loaded_data; massage_data(subject_id, classes_to_classify(c))];
	class_information = classifier_profile(classes_to_classify(c));
	class_label{1, c} = class_information{1, 1}.label;
end

for f = 1:length(set_of_features_to_try)
	accuracies = NaN(nRuns, nClassifiers);
	[feature_extracted_data, title_str{1, f}] = setup_features(loaded_data, f);
	for r = 1:nRuns
		[complete_train_set, complete_test_set, chance_baseline(f, r)] =...
					partition_and_relabel(feature_extracted_data, tr_percent);
		for k = 1:nClassifiers
			accuracies(r, k) = classifierList{k}(complete_train_set, complete_test_set, subject_id);
		end
	end
	mean_over_runs(f, :) = mean(accuracies);
	errorbars_over_runs(f, :) = std(accuracies) ./ nRuns;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [feature_extracted_data, title_str] = setup_features(loaded_data, feature_set_flag)

feature_extracted_data = [];
title_str = '';

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
pt_peak_col = nInterpolatedFeatures + 2;
rt_peak_col = nInterpolatedFeatures + 3;
qt_peak_col = nInterpolatedFeatures + 4;
qtc_peak_col = nInterpolatedFeatures + 5;
pr_peak_col = nInterpolatedFeatures + 6;
label_col = nInterpolatedFeatures + 7;

switch feature_set_flag
case 1
	% Returning only the averaged (within windows) standardized features with labels
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'Standardized features';
case 2
	feature_extracted_data = loaded_data(:, pt_peak_col);
	title_str = 'PT length';
case 3
	feature_extracted_data = loaded_data(:, rt_peak_col);
	title_str = 'RT length';
case 4
	feature_extracted_data = loaded_data(:, qt_peak_col);
	title_str = 'QT length';
case 5
	feature_extracted_data = loaded_data(:, qtc_peak_col);
	title_str = 'QT_c length';
case 6
	feature_extracted_data = loaded_data(:, pr_peak_col);
	title_str = 'PR length';
case 7
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col)];
	title_str = 'All peaks';
case 8
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, pt_peak_col),...
				  loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col)];
	title_str = 'All features';
otherwise
	error('Invalid feature set flag!');
end

feature_extracted_data = [feature_extracted_data, loaded_data(:, label_col)];
disp(sprintf('%s', title_str));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[loaded_data] = massage_data(subject_id, class_label)

result_dir = get_project_settings('results');
class_information = classifier_profile(class_label);
event = class_information{1, 1}.event;
pqrst_flag = class_information{1, 1}.pqrst_flag;
time_window = class_information{1, 1}.time_window;
slide_or_chunk = class_information{1, 1}.slide_or_chunk; 
target_dosage = class_information{1, 1}.dosage;
target_exp_sess = class_information{1, 1}.exp_session;

peaks_data = load(fullfile(result_dir, subject_id, sprintf('%s_pqrst_peaks_%d_%s.mat', event, time_window, slide_or_chunk)));

switch slide_or_chunk
case 'chunk'
	window_data = load(fullfile(result_dir, subject_id, sprintf('%s_chunking_%dmin_win.mat', event, time_window)));
case 'slide'
	window_data = load(fullfile(result_dir, subject_id, sprintf('%s_sliding_%dsec_win.mat', event, time_window)));
end
if pqrst_flag
	window_data = window_data.pqrst_mat;
else
	window_data = window_data.rr_mat;
end
assert(size(window_data, 1) == size(peaks_data.p_point, 1));
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
rr_length_col = nInterpolatedFeatures + 1;
dos_col = size(window_data, 2) - 1;
exp_sess_col = size(window_data, 2);

loaded_data = [window_data(:, 1:rr_length_col), (peaks_data.t_point(:, 1) - peaks_data.p_point(:, 1))];
loaded_data = [loaded_data, (peaks_data.t_point(:, 1) - peaks_data.r_point(:, 1))];
loaded_data = [loaded_data, (peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1))];
loaded_data = [loaded_data, ((peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)) .* sqrt(window_data(:, rr_length_col)))];
loaded_data = [loaded_data, (peaks_data.r_point(:, 1) - peaks_data.p_point(:, 1))];

temp_dosage_mat = NaN(size(loaded_data, 1), length(target_dosage));
for d = 1:length(target_dosage)
	temp_dosage_mat(:, d) = window_data(:, dos_col) == target_dosage(d);
end
temp_exp_sess_mat = NaN(size(loaded_data, 1), length(target_dosage));
for e = 1:length(target_exp_sess)
	temp_exp_sess_mat(:, e) = window_data(:, exp_sess_col) == target_exp_sess(e);
end

target_samples = find(peaks_data.q_point(:, 1) > 0 & sum(temp_dosage_mat, 2) & sum(temp_exp_sess_mat, 2));
loaded_data = [loaded_data(target_samples, :), repmat(class_label, length(target_samples), 1)];

