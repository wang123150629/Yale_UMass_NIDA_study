function[] = classify_ecg_driver(nClasses, features_set)

close all;

number_of_subjects = 1;
[subject_id, subject_session] = get_subject_ids(number_of_subjects);

for s = 1:length(subject_id)
	run_analysis_for_subj(subject_id{s}, subject_session{s}, features_set, nClasses);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = run_analysis_for_subj(subject_id, subject_session, features_set, nClasses)

% Preprocess data: Build / load interpolated ECG for the target sessions per subject
if ~exist(fullfile(get_project_settings('data'), subject_id, subject_session, sprintf('clean_interpolated_ecg.mat')))
	clean_interpolated_ecg = preprocess_ecg_data(subject_id, subject_session);
else
	load(fullfile(get_project_settings('data'), subject_id, subject_session,...
						sprintf('clean_interpolated_ecg.mat')));
end

for f = features_set
	% Load combination of features: setup_features will load a different combination of
	% (150 features + mean + std deviation + rr intervals)
	[loaded_data, title_str] = setup_features(subject_id, clean_interpolated_ecg, f);

	% Classify: Perfrom classification and plot the results
	classify_data(nClasses, loaded_data, subject_id, title_str, f);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, title_str] = setup_features(subject_id, clean_interpolated_ecg, feature_set_flag)

% Extracting only the features
features = clean_interpolated_ecg(:, 1:end-4);
% Extracting only the RR intervals
rr_intervals = clean_interpolated_ecg(:, end-3);
% Extracting only the means
interpol_means = clean_interpolated_ecg(:, end-2);
% Extracting only the std dev
interpol_std = clean_interpolated_ecg(:, end-1);
% Extracting only the labels
labels = clean_interpolated_ecg(:, end);

data = [];
title_str = '';

switch feature_set_flag
case 1
	% Returning only the (stanadardized) features with labels
	data = [features, labels];
	title_str = 'standardized features';
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
	% Standardizing the instances and returning the standardized instances with means and labels
	data = [features, interpol_means, labels];
	title_str = 'standardized features+mean';
case 6
	% Standardizing the instances and returning the standardized instances with std deviations and labels
	data = [features, interpol_means, interpol_std, labels];
	title_str = 'standardized features+mean+std';
case 7
	% standardizing the instances and returning the standardized instances, mean std dev,
	% rr intervals with labels
	data = [features, interpol_means, interpol_std, rr_intervals, labels];
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

otherwise, error('Invalid feature set flag!');
end

disp(sprintf('%s', title_str));

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

otherwise, error('Invalid feature set flag!');
end
%}

