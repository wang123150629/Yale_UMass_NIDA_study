function [accuracy, tpr, fpr, AUC] = two_class_logreg(complete_train_set, complete_test_set)

options.Display = 1;
% options.Method = 'lbfgs';
X = [ones(size(complete_train_set, 1), 1), complete_train_set(:, 1:end-1)]; % adding ones for the intercept term
Y = 2 * complete_train_set(:, end)-1; % changing labels from 0, 1 to -1, 1
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

class_0_idx = find(complete_test_set(:, end) == 0);
class_1_idx = find(complete_test_set(:, end) == 1);
tpr = length(find(class_guessed(class_1_idx) == 1)) / length(class_1_idx);
fpr = length(find(class_guessed(class_0_idx) == 1)) / length(class_0_idx);

[X, Y, T, AUC] = perfcurve(complete_test_set(:, end), class_guessed, 1);

% Fitting betas using glmfit
% betas = glmfit(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'binomial')';

