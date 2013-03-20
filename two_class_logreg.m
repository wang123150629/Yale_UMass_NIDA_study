function [accuracy, tpr, fpr, AUC] = two_class_logreg(train_set, test_set, save_betas)

interested_class = 1;

options.Display = 0;
% adding ones for the intercept term
X = [ones(size(train_set, 1), 1), train_set(:, 1:end-1)];
Y = train_set(:, end);
betas = minFunc(@LogisticLoss, zeros(size(X, 2), 1), options, X, Y)';

if ~isempty(save_betas)
	weight_analysis = struct();
	weight_analysis.betas = betas;
	weight_analysis.train_setm1 = mean(train_set(train_set(:, end) == -1, 1:end-1), 1);
	weight_analysis.train_set1 = mean(train_set(train_set(:, end) == 1, 1:end-1), 1);
	save(sprintf('%s/results/l2_betas/%s_weight_analysis.mat', pwd, save_betas), '-struct', 'weight_analysis');
end

% Adding ones to the test set since there is an intercept term
intercept_added_test_set = test_set(:, 1:end-1)';
intercept_added_test_set = [ones(1, size(intercept_added_test_set, 2)); intercept_added_test_set];

z = betas * intercept_added_test_set;
pos_class_prob = 1 ./ (1 + exp(-z));
neg_class_prob = 1 - pos_class_prob;
likelihood_ratio = neg_class_prob ./ pos_class_prob;
class_guessed = ones(size(intercept_added_test_set, 2), 1);
class_guessed(find(likelihood_ratio > 1)) = -1;

accuracy = sum(class_guessed == test_set(:, end)) * 100 / size(test_set, 1);

class_1_idx = find(test_set(:, end) == 1);
class_m1_idx = find(test_set(:, end) == -1);
tpr = length(find(class_guessed(class_1_idx) == interested_class)) / length(class_1_idx);
fpr = length(find(class_guessed(class_m1_idx) == interested_class)) / length(class_m1_idx);
[x_val, y_val, T, AUC] = perfcurve(test_set(:, end), class_guessed, interested_class);

% fprintf('tpr=%0.4f, fpr=%0.4f, AUC=%0.4f\n', tpr, fpr, AUC);
% tnr = length(find(class_guessed(class_m1_idx) == 0)) / length(class_m1_idx);
% fnr = length(find(class_guessed(class_1_idx) == 0)) / length(class_1_idx);
% [X, Y, T, AUC] = perfcurve(test_set(:, end), class_guessed, 0);
% fprintf('fnr=%0.4f, tnr=%0.4f, AUC=%0.4f\n', fnr, tnr, AUC);
% Fitting betas using glmfit
% betas = glmfit(train_set(:, 1:end-1), train_set(:, end), 'binomial')';
% Y = 2 * train_set(:, end)-1; % changing labels from 0, 1 to -1, 1
% options.Method = 'lbfgs';

