function[mean_over_runs, errorbars_over_runs, title_str, class_label, chance_baseline, tpr_over_runs, fpr_over_runs, auc_over_runs] =...
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
tpr_over_runs = NaN(nFeatures, nClassifiers);
fpr_over_runs = NaN(nFeatures, nClassifiers);
auc_over_runs = NaN(nFeatures, nClassifiers);

for c = 1:nAnalysis
	loaded_data = [loaded_data; massage_data(subject_id, classes_to_classify(c))];
	class_information = classifier_profile(classes_to_classify(c));
	class_label{1, c} = class_information{1, 1}.label;
end

for f = 1:length(set_of_features_to_try)
	accuracies = NaN(nRuns, nClassifiers);
	true_pos_rate = NaN(nRuns, nClassifiers);
	false_pos_rate = NaN(nRuns, nClassifiers);
	auc = NaN(nRuns, nClassifiers);
	[feature_extracted_data, title_str{1, f}] = setup_features(loaded_data, set_of_features_to_try(f));
	for r = 1:nRuns
		[complete_train_set, complete_test_set, chance_baseline(f, r)] =...
					partition_and_relabel(feature_extracted_data, tr_percent);
		for k = 1:nClassifiers
			[accuracies(r, k), true_pos_rate(r, k), false_pos_rate(r, k), auc(r, k)] =...
			classifierList{k}(complete_train_set, complete_test_set);
		end
	end
	mean_over_runs(f, :) = mean(accuracies, 1);
	errorbars_over_runs(f, :) = std(accuracies, [], 1) ./ nRuns;
	tpr_over_runs(f, :) = mean(true_pos_rate, 1);
	fpr_over_runs(f, :) = mean(false_pos_rate, 1);
	auc_over_runs(f, :) = mean(auc, 1);
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
p_height_col = nInterpolatedFeatures + 7;
q_height_col = nInterpolatedFeatures + 8;
r_height_col = nInterpolatedFeatures + 9;
s_height_col = nInterpolatedFeatures + 10;
t_height_col = nInterpolatedFeatures + 11;
dosage_col = nInterpolatedFeatures + 12;
expsess_col = nInterpolatedFeatures + 13;
label_col = nInterpolatedFeatures + 14;

switch feature_set_flag
case 1
	% Returning only the averaged (within windows) standardized features with labels
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'Std. feat';
case 2
	feature_extracted_data = loaded_data(:, rr_col);
	title_str = 'RR length';
case 3
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, rr_col)];
	title_str = 'std. feat+RR';
case 4
	feature_extracted_data = loaded_data(:, pt_peak_col);
	title_str = 'PT';
case 5
	feature_extracted_data = loaded_data(:, rt_peak_col);
	title_str = 'RT';
case 6
	feature_extracted_data = loaded_data(:, qt_peak_col);
	title_str = 'QT';
case 7
	feature_extracted_data = loaded_data(:, qtc_peak_col);
	title_str = 'QT_c';
case 8
	feature_extracted_data = loaded_data(:, pr_peak_col);
	title_str = 'PR';
case 9
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col)];
	title_str = 'All dist';
case 10
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, rr_col)];
	title_str = 'All dist+RR';
case 11
	feature_extracted_data = [loaded_data(:, p_height_col), loaded_data(:, q_height_col), loaded_data(:, r_height_col),...
				  loaded_data(:, s_height_col), loaded_data(:, t_height_col)];
	title_str = 'All heights';
case 12
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, p_height_col),...
				  loaded_data(:, q_height_col), loaded_data(:, r_height_col), loaded_data(:, s_height_col),...
				  loaded_data(:, t_height_col)];
	title_str = 'All dist+heights';
case 13
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, pt_peak_col),...
				  loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, p_height_col),...
				  loaded_data(:, q_height_col), loaded_data(:, r_height_col), loaded_data(:, s_height_col),...
				  loaded_data(:, t_height_col), loaded_data(:, rr_col)];
	title_str = 'All features';
otherwise
	error('Invalid feature set flag!');
end

feature_extracted_data = [feature_extracted_data, loaded_data(:, dosage_col), loaded_data(:, expsess_col), loaded_data(:, label_col)];
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

peaks_data = load(fullfile(result_dir, subject_id, sprintf('%s_pqrst_peaks_%s%d.mat', event, slide_or_chunk, time_window)));
window_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s%d_win.mat', event, slide_or_chunk, time_window)));
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
loaded_data = [loaded_data, peaks_data.p_point(:, 2)];
loaded_data = [loaded_data, peaks_data.q_point(:, 2)];
loaded_data = [loaded_data, peaks_data.r_point(:, 2)];
loaded_data = [loaded_data, peaks_data.s_point(:, 2)];
loaded_data = [loaded_data, peaks_data.t_point(:, 2)];

temp_dosage_mat = NaN(size(loaded_data, 1), length(target_dosage));
for d = 1:length(target_dosage)
	temp_dosage_mat(:, d) = window_data(:, dos_col) == target_dosage(d);
end
temp_exp_sess_mat = NaN(size(loaded_data, 1), length(target_dosage));
for e = 1:length(target_exp_sess)
	temp_exp_sess_mat(:, e) = window_data(:, exp_sess_col) == target_exp_sess(e);
end

target_samples = find(peaks_data.q_point(:, 1) > 0 & sum(temp_dosage_mat, 2) & sum(temp_exp_sess_mat, 2));
loaded_data = [loaded_data(target_samples, :), window_data(target_samples, dos_col),...
	       window_data(target_samples, exp_sess_col), repmat(class_label, length(target_samples), 1)];

