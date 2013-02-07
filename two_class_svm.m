function [accuracy] = two_class_svm(complete_train_set, complete_test_set, subject_id)

svmStruct = svmtrain(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'kernel_function',...
						'quadratic', 'method', 'LS', 'autoscale', false);
class_guessed = svmclassify(svmStruct, complete_test_set(:, 1:end-1));
accuracy = sum(class_guessed == complete_test_set(:, end)) * 100 / size(complete_test_set, 1);

