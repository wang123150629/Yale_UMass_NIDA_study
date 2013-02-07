function [accuracy] = two_class_logreg(complete_train_set, complete_test_set, subject_id)

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

