function[] = classify_ecg(two_vs_multi_class)

close all;

number_of_subjects = 2;
[subject_id, subject_session] = get_subject_ids(number_of_subjects);

% for f = [1:8, 25]
for f = [2]
	for s = 1:length(subject_id)
		run_analysis_for_subj(two_vs_multi_class, subject_id{s}, subject_session{s}, f)
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = run_analysis_for_subj(two_vs_multi_class, subject_id, subject_session, feature_set_flag)

root_dir = pwd;
data_dir = fullfile(root_dir, 'data');
global write_dir
write_dir = fullfile(root_dir, 'plots');
global image_format
image_format = 'png';

% Build / load the interpolated ECG for the target sessions
if ~exist(fullfile(data_dir, subject_id, subject_session, sprintf('clean_interpolated_ecg.mat')))
	clean_interpolated_ecg = get_raw_ecg_data_per_dose(subject_id, subject_session);
else
	load(fullfile(data_dir, subject_id, subject_session, sprintf('clean_interpolated_ecg.mat')));
end

[loaded_data, title_str] = setup_features(feature_set_flag, clean_interpolated_ecg, subject_id);

%{
switch two_vs_multi_class
case 'two_class'
	nRuns = 10;
	tr_percent = 80; % training data size in percentage
	two_class_comparisons(nRuns, tr_percent, loaded_data, subject_id, title_str, feature_set_flag);
case 'multi_class'
	nRuns = 1;
	tr_percent = 80; % training data size in percentage
	multi_class_comparisons(nRuns, tr_percent, loaded_data, subject_id, title_str, feature_set_flag);
otherwise
	error('Invalid call!');
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, title_str] = setup_features(feature_set_flag, clean_interpolated_ecg, subject_id)

global write_dir;
global image_format;

features = clean_interpolated_ecg(:, 1:end-2);
rr_intervals = clean_interpolated_ecg(:, end-1);
labels = clean_interpolated_ecg(:, end);
data = [];
title_str = '';

switch feature_set_flag
case 1
	% removing the rr intervals and returning the features with the labels
	data = [features, labels];
	title_str = 'features only';
case 2
	% standardizing the instances and returning the standardized instances with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	
	for l = 1:4
		figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
		plot(data(labels == l, :)'); ylim([-5, 5]);
		xlabel('features'); ylabel('standardized millivolts');
		file_name = sprintf('%s/subj_%s_stand_%d_rr_inter', write_dir, subject_id, l);
		savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));
	end

	data = [data, labels];
	title_str = 'standardized features';
case 3
	% returning the mean of the instances with labels
	data = [mean(features, 2), labels];
	title_str = 'mean(instances) only';
case 4
	% returning the std dev of the instances with labels
	data = [std(features, [], 2), labels];
	title_str = 'std(instances) only';
case 5
	% returning the std dev of the instances with labels
	data = [rr_intervals, labels];
	title_str = 'RR intervals only';
case 6
	% standardizing the instances and returning the standardized instances with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), labels];
	title_str = 'standardized features+mean';
case 7
	% standardizing the instances and returning the standardized instances with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), std(features, [], 2), labels];
	title_str = 'standardized features+mean+std';
case 8
	% standardizing the instances and returning the standardized instances with labels
	data = bsxfun(@rdivide, bsxfun(@minus, features, mean(features, 2)), std(features, [], 2));
	data = [data, mean(features, 2), std(features, [], 2), rr_intervals, labels];
	title_str = 'standardized features+mean+std+rr intervals';
case 25
	% Scrambling the labels
	target_idx = labels <= 4;

	labels = labels(target_idx);
	permuted_idx = randperm(length(labels));
	% Scrambling the labels 1, 2, 3, 4 only recall 5 is a copy of 2, 3, 4
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = two_class_comparisons(nRuns, tr_percent, interpolated_ecg, subject_id, title_str, feature_set_flag)

global write_dir;
global image_format;

% classes: 1 - baseline, 2 - 8mg, 3 - 16mg, 4 - 32mg
classes_to_compare = [1, 2; 1, 3; 1, 4; 2, 3; 2, 4; 3, 4; 1, 5];
nComparisons = size(classes_to_compare, 1);
classifier = {'logistic', 'svm'};

accuracy_classes = zeros(size(classes_to_compare, 1), nRuns, length(classifier));
chance_baseline = zeros(size(classes_to_compare, 1), nRuns, length(classifier));
mean_accuracy_classes = [];
errorbars_accuracy_classes = [];
for k = 1:length(classifier)
	for r = 1:nRuns
		for c = 1:size(classes_to_compare, 1)
			[accuracy_classes(c, r, k), chance_baseline(c, r, k)] =...
				partition_and_classify_two(interpolated_ecg, classes_to_compare(c, :),...
				tr_percent, classifier{k});
		end
	end
	mean_accuracy_classes = [mean_accuracy_classes; mean(accuracy_classes(:, :, k), 2)'];
	errorbars_accuracy_classes = [errorbars_accuracy_classes; std(accuracy_classes(:, :, k), 0, 2)'./ sqrt(nRuns)];
end

figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
errorbar(1:nComparisons, mean_accuracy_classes(1, :), errorbars_accuracy_classes(1, :), 'r', 'LineWidth', 2); hold on;
errorbar(1:nComparisons, mean_accuracy_classes(2, :), errorbars_accuracy_classes(2, :), 'b', 'LineWidth', 2);
plot(mean(chance_baseline(:, :, 1), 2)', 'ko-', 'LineWidth', 2);
ylim([40, 100]); xlim([1, nComparisons]); grid on;
xlabel('Analysis'); ylabel('Accuracies');
title(sprintf('%s-Two class, avg(%d runs)\n%s', strrep(subject_id, '_', '-'), nRuns, title_str));
legend('log. reg', 'svm(2)', 'chance', 'Location', 'SouthWest', 'Orientation', 'Horizontal');
set(gca, 'XTickLabel', {'base vs. 8mg', 'base vs. 16mg', 'base vs. 32mg', '8mg vs. 16mg', '8mg vs. 32mg', '16mg vs. 32mg', 'base vs. all'});
file_name = sprintf('%s/subj_%s_feat%d_class2_perf', write_dir, subject_id, feature_set_flag);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[accuracy, chance_baseline] = partition_and_classify_two(ecg_x, classes_to_compare, tr_percent, classifier)

complete_train_set = [];
complete_test_set = [];
chance_baseline = [];
for c = 1:length(classes_to_compare)
	[train_set, test_set] = fetch_training_instances(classes_to_compare(c), ecg_x, tr_percent);
	complete_train_set = [complete_train_set; train_set];
	complete_test_set = [complete_test_set; test_set];
	chance_baseline = [chance_baseline, size(test_set, 1)];
end
chance_baseline = max(chance_baseline) / sum(chance_baseline) * 100;

%{
top_how_many = 150;
% Removing the labels
train_set_minus_label = complete_train_set(:, 1:end-1);
% Centering the data
train_set_minus_label = bsxfun(@minus, train_set_minus_label, mean(train_set_minus_label));
% PCA on the whole training set
[PC, score, latent] = princomp(train_set_minus_label);
% Build design matrix with top k features
train_set_minus_label = train_set_minus_label * PC(:, 1:top_how_many);
% Adding the labels back
complete_train_set = [train_set_minus_label, complete_train_set(:, end)];
% Removing the test labels
test_set_minus_label = complete_test_set(:, 1:end-1);
% Build design matrix with top k features
test_set_minus_label = test_set_minus_label * PC(:, 1:top_how_many);
% Adding the labels back
complete_test_set = [test_set_minus_label, complete_test_set(:, end)];
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
plot(log(latent));
xlabel('Principal components'); ylabel('log(eigenvalues)'); title(sprintf('PCA on interpolated ECG b/w RR'));
%}

% change labels
unique_labels = unique(complete_train_set(:, end));
assert(length(unique_labels) == 2);
% Reassigning the labels to 0 and 1 for logistic regression
complete_train_set(find(unique_labels(1) == complete_train_set(:, end)), end) = 0;
complete_train_set(find(unique_labels(2) == complete_train_set(:, end)), end) = 1;
complete_test_set(find(unique_labels(1) == complete_test_set(:, end)), end) = 0;
complete_test_set(find(unique_labels(2) == complete_test_set(:, end)), end) = 1;

switch classifier
case 'logistic'
	% Fitting betas using glmfit
	betas = glmfit(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'binomial')';

	% Adding ones to the test set since there is an intercept term that comes from glmfit
	intercept_added_test_set = complete_test_set(:, 1:end-1)';
	intercept_added_test_set = [ones(1, size(intercept_added_test_set, 2)); intercept_added_test_set];
	z = betas * intercept_added_test_set;
	pos_class_prob = 1 ./ (1 + exp(-z));
	neg_class_prob = 1 - pos_class_prob;
	likelihood_ratio = neg_class_prob ./ pos_class_prob;
	class_guessed = ones(size(intercept_added_test_set, 2), 1);
	class_guessed(find(likelihood_ratio > 1)) = 0;
case 'svm'
	svmStruct = svmtrain(complete_train_set(:, 1:end-1), complete_train_set(:, end),...
						'kernel_function', 'quadratic', 'method', 'LS');
	class_guessed = svmclassify(svmStruct, complete_test_set(:, 1:end-1));
otherwise
	error('Invalid classifier!');
end
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[train_set, test_set] = fetch_training_instances(class, ecg_x, tr_percent)

target_idx = find(ecg_x(:, end) == class);
all_samples = target_idx(randperm(length(target_idx)));
tr_percent = round_to(tr_percent * length(all_samples) / 100, 0);
train_samples = all_samples(1:tr_percent);
test_samples = setdiff(all_samples, train_samples);
assert(isempty(intersect(train_samples, test_samples)));
train_set = ecg_x(train_samples, :);
test_set = ecg_x(test_samples, :);
% dispf(sprintf('class=%d no. of train samples=%d', class, size(train_set, 1)));
% dispf(sprintf('class=%d no. of test samples=%d', class, size(test_set, 1)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = multi_class_comparisons(nRuns, tr_percent, interpolated_ecg, subject_id, title_str, feature_set_flag)

global write_dir;
global image_format;

classifier = {'naive', 'multi'};
nClassifiers = length(classifier);
categories = 1:4;

accuracy_classes = zeros(nRuns, length(classifier));
chance_baseline = zeros(nRuns, length(classifier));
mean_accuracy_classes = [];
errorbars_accuracy_classes = [];
for k = 1:nClassifiers
	for r = 1:nRuns
		[accuracy_classes(r, k), chance_baseline(r, k)] =...
			partition_and_classify_multi(interpolated_ecg, tr_percent, classifier{k}, categories);
	end
	mean_accuracy_classes = [mean_accuracy_classes, mean(accuracy_classes(:, k))];
	errorbars_accuracy_classes = [errorbars_accuracy_classes, std(accuracy_classes(:, k)) ./ sqrt(nRuns)];
end

figure(); set(gcf, 'Position', [10, 10, 600, 600]);
errorbar(1:nClassifiers, mean_accuracy_classes(1, :), errorbars_accuracy_classes(1, :), 'r', 'LineWidth', 2); hold on;
plot(chance_baseline(1, :), 'ko-', 'LineWidth', 2);
ylim([0, 100]); xlim([1, nClassifiers]); grid on;
xlabel('Classifier'); ylabel('Accuracies');
title(sprintf('%s-Four class\navg(%d runs)', strrep(subject_id, '_', '-'), nRuns));
legend('Accuracy', 'chance', 'Location', 'SouthWest', 'Orientation', 'Horizontal');
set(gca, 'XTickLabel', {'Naive Bayes', '', '', '', '', '', '', '', '', '', 'Multinomial'});
file_name = sprintf('%s/subj_%s_four_class_perf', write_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[accuracy, chance_baseline] = partition_and_classify_multi(ecg_x, tr_percent, classifier, categories)

complete_train_set = [];
complete_test_set = [];
chance_baseline = [];
for c = 1:length(categories)
	[train_set, test_set] = fetch_training_instances(categories(c), ecg_x, tr_percent);
	complete_train_set = [complete_train_set; train_set];
	complete_test_set = [complete_test_set; test_set];
	chance_baseline = [chance_baseline, size(test_set, 1)];
end
chance_baseline = max(chance_baseline) / sum(chance_baseline) * 100;

switch classifier
case 'naive'
	nb_out = NaiveBayes.fit(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'dist', 'kernel');
	class_guessed = nb_out.predict(complete_test_set(:, 1:end-1));

case 'multi'
	% Fitting betas using glmfit
	betas = mnrfit(complete_train_set(:, 1:end-1), complete_train_set(:, end));
	test_sample_prob = mnrval(betas, complete_test_set(:, 1:end-1));
	nan_idx = sum(isnan(test_sample_prob), 2);
	test_sample_prob = test_sample_prob(~nan_idx, :);
	complete_test_set = complete_test_set(~nan_idx, end);
	[max_prob, class_guessed] = max(test_sample_prob');
	class_guessed = class_guessed';
otherwise
	error('Invalid classifier!');
end
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);

