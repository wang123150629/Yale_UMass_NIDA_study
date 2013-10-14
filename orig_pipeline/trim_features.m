function[train_set, test_set, feature_str] = trim_features(complete_train_set, complete_test_set, feature)

% for train set
[train_set, feature_str] = setup_features(complete_train_set, feature);
% for test set
test_set = setup_features(complete_test_set, feature);
assert(size(train_set, 2) >= 4);

label_col = size(train_set, 2);
expsess_col = size(train_set, 2)-1;
dosage_col = size(train_set, 2)-2;
feature_cols = 1:size(train_set, 2)-3;
train_set = train_set(:, [feature_cols, label_col]);
test_set = test_set(:, [feature_cols, label_col]);

