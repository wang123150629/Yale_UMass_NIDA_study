function[mean_over_runs, errorbars_over_runs, chance_baseline] = classify_data(nClasses, data,...
									subject_id, feature_set_flag)

switch nClasses
case 2
	nRuns = 10;
	tr_percent = 80; % training data size in percentage
	classifierList = {@two_class_logreg, @two_class_svm};
	% classes: 1 - baseline, 2 - 8mg, 3 - 16mg, 4 - 32mg
	classes_to_compare = [1, 2; 1, 3; 1, 4; 2, 3; 2, 4; 3, 4; 1, 5];
case 4
	nRuns = 1;
	tr_percent = 80; % training data size in percentage
	keyboard
otherwise
	error('Invalid call!');
end
nComparisons = size(classes_to_compare, 1);

accuracies = NaN(nRuns, nComparisons, numel(classifierList));
chance_baseline = NaN(nRuns, nComparisons);
mean_over_runs = NaN(nComparisons, numel(classifierList));
errorbars_over_runs = NaN(nComparisons, numel(classifierList));
for c = 1:nComparisons
	for r = 1:nRuns
		[complete_train_set, complete_test_set, chance_baseline(r, c)] =...
				partition_and_relabel(classes_to_compare(c, :), data, tr_percent);
		for k = 1:numel(classifierList)
			accuracies(r, c, k) = classifierList{k}(complete_train_set, complete_test_set,...
					      subject_id, feature_set_flag, classes_to_compare(c, :));
			close all;
		end
	end
end

mean_over_runs = reshape(mean(accuracies), nComparisons, numel(classifierList))';
errorbars_over_runs = reshape(std(accuracies), nComparisons, numel(classifierList))' ./ sqrt(nRuns);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [accuracy] = two_class_logreg(complete_train_set, complete_test_set, subject_id,...
					feature_set_flag, classes_to_compare)

% Fitting betas using glmfit
% betas = glmfit(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'binomial')';

options.Method = 'lbfgs';
X = complete_train_set(:, 1:end-1);
X = [ones(size(X, 1), 1), X];
Y = 2 * complete_train_set(:, end)-1;
betas = minFunc(@LogisticLoss, zeros(size(X, 2), 1), options, X, Y)';

% Adding ones to the test set since there is an intercept term that comes from glmfit
intercept_added_test_set = complete_test_set(:, 1:end-1)';
intercept_added_test_set = [ones(1, size(intercept_added_test_set, 2)); intercept_added_test_set];

z = betas * intercept_added_test_set;
pos_class_prob = 1 ./ (1 + exp(-z));
neg_class_prob = 1 - pos_class_prob;
likelihood_ratio = neg_class_prob ./ pos_class_prob;

class_guessed = ones(size(intercept_added_test_set, 2), 1);
class_guessed(find(likelihood_ratio > 1)) = 0;
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);

[lower, upper, title_str] = plot_ten_minute_means(subject_id, classes_to_compare, false);
scaled_betas = scale_data(betas, lower, upper);
hold on;
plot(scaled_betas, 'k-');
title(sprintf('%s\noverloaded with lbfgs betas', title_str));
file_name = sprintf('%s/subj_%s_feat%d_logreg_%s', get_project_settings('plots'), subject_id, feature_set_flag,...
						 strrep(num2str(classes_to_compare), ' ', ''));
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [accuracy] = two_class_svm(complete_train_set, complete_test_set, subject_id,...
					feature_set_flag, classes_to_compare)

svmStruct = svmtrain(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'kernel_function',...
						'quadratic', 'method', 'LS', 'autoscale', false);
class_guessed = svmclassify(svmStruct, complete_test_set(:, 1:end-1));
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);

%{
top_how_many = 50;

zero_idx = find(svmStruct.Alpha > 0);
zero_support_vectors = svmStruct.SupportVectors(zero_idx, :);
zero_alpha_weights = svmStruct.Alpha(zero_idx);
[sorted_val_zero, sort_idx_zero] = sort(zero_alpha_weights, 'descend');
% zero_weighted = svmStruct.Alpha(zero_idx)' * zero_support_vectors;
% zero_weighted = mean(zero_support_vectors(sort_idx_zero(1:top_how_many), :));
zero_weighted = sorted_val_zero(1:top_how_many)' * zero_support_vectors(sort_idx_zero(1:top_how_many), :);

one_idx = find(svmStruct.Alpha < 0);
one_support_vectors = svmStruct.SupportVectors(one_idx, :);
one_alpha_weights = svmStruct.Alpha(one_idx);
[sorted_val_one, sort_idx_one] = sort(one_alpha_weights);
% one_weighted = abs(svmStruct.Alpha(one_idx))' * one_support_vectors;
% one_weighted = mean(one_support_vectors(sort_idx_one(1:top_how_many), :));
one_weighted = abs(sorted_val_one(1:top_how_many))' * one_support_vectors(sort_idx_one(1:top_how_many), :);

[lower, upper, title_str] = plot_ten_minute_means(subject_id, classes_to_compare, false);
hold on;
zero_weighted = scale_data(zero_weighted, lower, upper);
plot(zero_weighted, 'k-'); hold on;
one_weighted = scale_data(one_weighted, lower, upper);
plot(one_weighted, 'k--');
title(sprintf('%s\noverloaded with mean of top %d support vectors', title_str, top_how_many));

file_name = sprintf('%s/subj_%s_feat%d_svm_%s', get_project_settings('plots'), subject_id, feature_set_flag,...
						 strrep(num2str(classes_to_compare), ' ', ''));
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[complete_train_set, complete_test_set, chance_baseline] = partition_and_relabel(classes_to_compare,...
									data, tr_percent)
assert(size(classes_to_compare, 1) == 1);
assert(tr_percent > 0 & tr_percent < 100);

complete_train_set = [];
complete_test_set = [];
chance_baseline = [];
for c = 1:length(classes_to_compare)
	[train_set, test_set] = fetch_training_instances(classes_to_compare(c), data, tr_percent);
	complete_train_set = [complete_train_set; train_set];
	complete_test_set = [complete_test_set; test_set];
	chance_baseline = [chance_baseline, size(test_set, 1)];
end
chance_baseline = max(chance_baseline) / sum(chance_baseline) * 100;

% change labels
unique_labels = unique(complete_train_set(:, end));
% Reassigning the labels to 0 and 1 for logistic regression
if length(unique_labels) == 2
	complete_train_set(find(unique_labels(1) == complete_train_set(:, end)), end) = 0;
	complete_train_set(find(unique_labels(2) == complete_train_set(:, end)), end) = 1;
	complete_test_set(find(unique_labels(1) == complete_test_set(:, end)), end) = 0;
	complete_test_set(find(unique_labels(2) == complete_test_set(:, end)), end) = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[train_set, test_set] = fetch_training_instances(class, data, tr_percent)

target_idx = find(data(:, end) == class);
all_samples = target_idx(randperm(length(target_idx)));
tr_percent = round_to(tr_percent * length(all_samples) / 100, 0);
train_samples = all_samples(1:tr_percent);
test_samples = setdiff(all_samples, train_samples);
assert(isempty(intersect(train_samples, test_samples)));
train_set = data(train_samples, :);
test_set = data(test_samples, :);
% dispf(sprintf('class=%d no. of train samples=%d', class, size(train_set, 1)));
% dispf(sprintf('class=%d no. of test samples=%d', class, size(test_set, 1)));

%{

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = multi_class_comparisons(nRuns, tr_percent, interpolated_ecg, subject_id)

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
%}

%{
PCA
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

%{
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
errorbar(1:nComparisons, mean_over_runs(1, :), errorbars_over_runs(1, :), 'r', 'LineWidth', 2); hold on;
errorbar(1:nComparisons, mean_over_runs(2, :), errorbars_over_runs(2, :), 'b', 'LineWidth', 2);
plot(mean(chance_baseline), 'ko-', 'LineWidth', 2);
ylim([40, 100]); xlim([0.5, nComparisons+0.5]); grid on;
xlabel('Analysis'); ylabel('Accuracies');
title(sprintf('%s-Two class, avg(%d runs)\n%s', strrep(subject_id, '_', '-'), nRuns, title_str));
legend('log. reg', 'svm(2)', 'chance', 'Location', 'SouthWest', 'Orientation', 'Horizontal');
set(gca, 'XTickLabel', {'base vs. 8mg', 'base vs. 16mg', 'base vs. 32mg', '8mg vs. 16mg', '8mg vs. 32mg', '16mg vs. 32mg', 'base vs. all'});
file_name = sprintf('%s/subj_%s_feat%d_class2_perf', get_project_settings('plots'), subject_id, feature_set_flag);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
%}

