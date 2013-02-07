function[] = classify_ecg_driver(subject_id, time_window, slide_or_chunk, pqrst_flag, features_set, nClasses)

% classify_ecg_driver('P20_040', 30, 'slide', true, [1], 2)

result_dir = get_project_settings('results');

loaded_data = massage_data(subject_id, time_window, slide_or_chunk, pqrst_flag);

results_per_featureset = {};
title_str = {};
for f = 1:length(features_set)
	[feature_extracted_data, title_str{f}] = setup_features(loaded_data, features_set(f));

	[results_per_featureset{f, 1}, results_per_featureset{f, 2}, results_per_featureset{f, 3}] =...
					classify_data(subject_id, nClasses, feature_extracted_data);
end

classifier_results = struct();
classifier_results.title_str = title_str;
classifier_results.results_per_featureset = results_per_featureset;
save(fullfile(result_dir, subject_id, sprintf('classifier_results')), '-struct', 'classifier_results');

keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [feature_extracted_data, title_str] = setup_features(loaded_data, feature_set_flag)

feature_extracted_data = [];
title_str = '';

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
start_hh_col = nInterpolatedFeatures + 2;
start_mm_col = nInterpolatedFeatures + 3;
end_hh_col = nInterpolatedFeatures + 4;
end_mm_col = nInterpolatedFeatures + 5;
nSamples_col = nInterpolatedFeatures + 6;
dosage_col = nInterpolatedFeatures + 7;
p_peak_location = nInterpolatedFeatures + 8;
p_peak_height = nInterpolatedFeatures + 9;
q_peak_location = nInterpolatedFeatures + 10;
q_peak_height = nInterpolatedFeatures + 11;
r_peak_location = nInterpolatedFeatures + 12;
r_peak_height = nInterpolatedFeatures + 13;
s_peak_location = nInterpolatedFeatures + 14;
s_peak_height = nInterpolatedFeatures + 15;
t_peak_location = nInterpolatedFeatures + 16;
t_peak_height = nInterpolatedFeatures + 17;
exp_sess_col = nInterpolatedFeatures + 18;

labels = loaded_data(:, dosage_col);
sessions = loaded_data(:, exp_sess_col);

switch feature_set_flag
case 1
	% Returning only the averaged (within windows) standardized features with labels
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'Standardized features';
case 2
	feature_extracted_data = loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location);
	title_str = 'QT length';
case 3
	feature_extracted_data = (loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location)).*sqrt(loaded_data(:, rr_col));
	title_str = 'QT_c length';
case 4
	feature_extracted_data = loaded_data(:, t_peak_location) - loaded_data(:, p_peak_location);
	title_str = 'PT length';
case 5
	feature_extracted_data = loaded_data(:, t_peak_location) - loaded_data(:, r_peak_location);
	title_str = 'RT length';
case 6
	feature_extracted_data = loaded_data(:, r_peak_location) - loaded_data(:, p_peak_location);
	title_str = 'PR length';
case 7
	feature_extracted_data = [loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location),...
		(loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location)).*sqrt(loaded_data(:, rr_col)),...
		loaded_data(:, t_peak_location) - loaded_data(:, p_peak_location),...
		loaded_data(:, t_peak_location) - loaded_data(:, r_peak_location),...
		loaded_data(:, r_peak_location) - loaded_data(:, p_peak_location)];
	title_str = 'All peaks';
case 8
	feature_extracted_data = [loaded_data(:, ecg_col),...
		loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location),...
		(loaded_data(:, t_peak_location) - loaded_data(:, q_peak_location)).*sqrt(loaded_data(:, rr_col)),...
		loaded_data(:, t_peak_location) - loaded_data(:, p_peak_location),...
		loaded_data(:, t_peak_location) - loaded_data(:, r_peak_location),...
		loaded_data(:, r_peak_location) - loaded_data(:, p_peak_location)];
	title_str = 'All features';

otherwise, error('Invalid feature set flag!');
end

feature_extracted_data = [feature_extracted_data, sessions];
feature_extracted_data = [feature_extracted_data, labels];

disp(sprintf('%s', title_str));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [loaded_data] = massage_data(subject_id, time_window, slide_or_chunk, pqrst_flag);

loaded_data = [];

result_dir = get_project_settings('results');
if exist(fullfile(result_dir, subject_id, sprintf('pqrst_peaks_%d_%s.mat', time_window, slide_or_chunk)))
	pqrst_peaks = load(fullfile(result_dir, subject_id, sprintf('pqrst_peaks_%d_%s.mat', time_window, slide_or_chunk)));
else
	error('Missing *pqrst_peaks*.mat!');
end

switch slide_or_chunk
case 'chunk'
	if ~exist(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', time_window)))
		error(sprintf('File ''chunks_%d_min.mat'' does not exist!', time_window));
	else
		load(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', time_window)));
		window_data = chunks_m_min;
	end
case 'slide'
	if ~exist(fullfile(result_dir, subject_id, sprintf('sliding_%dsec_win.mat', time_window)))
		error(sprintf('File ''sliding_%dsec_win.mat'' does not exist!', time_window));
	else
		load(fullfile(result_dir, subject_id, sprintf('sliding_%dsec_win.mat', time_window)));
		window_data = sliding_ksec_win;
	end
end

exp_sessions = [];
for w = 1:numel(window_data)
	if pqrst_flag
		loaded_data = [loaded_data; window_data{w}.pqrst];
	else
		loaded_data = [loaded_data; window_data{w}.rr];
	end
	exp_sessions = [exp_sessions; repmat(w, size(window_data{w}.rr, 1), 1)];
end
assert(size(loaded_data, 1) == size(pqrst_peaks.p_point, 1));

loaded_data = [loaded_data, pqrst_peaks.p_point];
loaded_data = [loaded_data, pqrst_peaks.q_point];
loaded_data = [loaded_data, pqrst_peaks.r_point];
loaded_data = [loaded_data, pqrst_peaks.s_point];
loaded_data = [loaded_data, pqrst_peaks.t_point];
loaded_data = [loaded_data, exp_sessions];

% only few samples have the five peaks so ... I am retaining only those samples
target_sample_idx = find(pqrst_peaks.p_point(:, 1));
loaded_data = loaded_data(target_sample_idx, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
for l = 1:4
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	plot(data(labels == l, :)'); ylim([-5, 5]);
	xlabel('features'); ylabel('standardized millivolts');
	file_name = sprintf('%s/subj_%s_stand_%d_rr_inter', get_project_settings('plots'), subject_id, l);
	savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
end
switch feature_set_flag
case 1
	% Returning only the features with the labels
	data = [features, labels];
	title_str = 'features only';
case 2
	% Standardizing the instances and returning the standardized instances with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, labels];
	title_str = 'standardized features';
case 3
	% Returning the mean of the instances with labels
	data = [mean(features, 2), labels];
	title_str = 'mean(instances) only';
case 4
	% Returning the std dev of the instances with labels
	data = [std(features, [], 2), labels];
	title_str = 'std(instances) only';
case 5
	% Returning the RR intervals with labels
	data = [rr_intervals, labels];
	title_str = 'RR intervals only';
case 6
	% Standardizing the instances and returning the standardized instances with means and labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), labels];
	title_str = 'standardized features+mean';
case 7
	% Standardizing the instances and returning the standardized instances with std deviations and labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), std(features, [], 2), labels];
	title_str = 'standardized features+mean+std';
case 8
	% standardizing the instances and returning the standardized instances, mean std dev,
	% rr intervals with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), std(features, [], 2), rr_intervals, labels];
	title_str = 'standardized features+mean+std+rr intervals';
case 25
	% Scrambling the labels
	target_idx = labels <= 4;

	labels = labels(target_idx);
	permuted_idx = randperm(length(labels));
	% Scrambling the labels 1, 2, 3, 4 only, recall label 5 is a copy of data from labels 2, 3, 4
	scrambled_labels = labels(permuted_idx);
	% Selecting instances corresponding to the 1, 2, 3, 4
	features = features(target_idx, :);

	% Fetching indices of labels 2 through 4 from the scrambled labels since we would like to repeat them
	dosage_idx = scrambled_labels >= 2;
	% Copying the associated features
	features = [features; features(dosage_idx, :)];
	% Adding label '5' to the new copied instances
	scrambled_labels = [scrambled_labels; repmat(max(labels)+1, sum(dosage_idx), 1)];

	data = [features, scrambled_labels];
	title_str = 'scrambled labels';

case 2
	% Returning the mean of the instances with labels
	data = [interpol_means, labels];
	title_str = 'mean(instances) only';
case 3
	% Returning the std dev of the instances with labels
	data = [interpol_std, labels];
	title_str = 'std(instances) only';
case 4
	% Returning the RR intervals with labels
	data = [rr_intervals, labels];
	title_str = 'RR intervals only';
case 5
	% Returning the standardized instances with means and labels
	data = [features, interpol_means, labels];
	title_str = 'std features+mean';
case 6
	% Returning the standardized instances with mean, std deviations and labels
	data = [features, interpol_means, interpol_std, labels];
	title_str = 'std features+mean+std';
case 7
	% Returning the standardized instances, mean, std dev and rr intervals with labels
	data = [features, interpol_means, interpol_std, rr_intervals, labels];
	title_str = 'std features+mean+std+rr intervals';
case 25
	% Scrambling the labels
	target_idx = labels <= 4;

	labels = labels(target_idx);
	permuted_idx = randperm(length(labels));
	% Scrambling the labels 1, 2, 3, 4 only, recall label 5 is a copy of data from labels 2, 3, 4
	scrambled_labels = labels(permuted_idx);
	% Selecting instances corresponding to the 1, 2, 3, 4
	features = features(target_idx, :);

	% Fetching indices of labels 2 through 4 from the scrambled labels since we would like to repeat them
	dosage_idx = scrambled_labels >= 2;
	% Copying the associated features
	features = [features; features(dosage_idx, :)];
	% Adding label '5' to the new copied instances
	scrambled_labels = [scrambled_labels; repmat(max(labels)+1, sum(dosage_idx), 1)];

	data = [features, scrambled_labels];
	title_str = 'scrambled labels';

otherwise, error('Invalid feature set flag!');
end
%}
%{
case 25
	% Scrambling the labels
	target_idx = labels <= 4;

	labels = labels(target_idx);
	permuted_idx = randperm(length(labels));
	% Scrambling the labels 1, 2, 3, 4 only, recall label 5 is a copy of data from labels 2, 3, 4
	scrambled_labels = labels(permuted_idx);
	% Selecting instances corresponding to the 1, 2, 3, 4
	features = features(target_idx, :);

	% Fetching indices of labels 2 through 4 from the scrambled labels since we would like to repeat them
	dosage_idx = scrambled_labels >= 2;
	% Copying the associated features
	features = [features; features(dosage_idx, :)];
	% Adding label '5' to the new copied instances
	scrambled_labels = [scrambled_labels; repmat(max(labels)+1, sum(dosage_idx), 1)];

	data = [features, scrambled_labels];
	title_str = 'scrambled labels';
%}


