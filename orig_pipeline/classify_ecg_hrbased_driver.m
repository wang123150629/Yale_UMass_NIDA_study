function[] = classify_ecg_hrbased_driver(tr_percent)

% classify_ecg_hrbased_driver(50)
% This is a clone of classify_ecg_driver()

nSubjects = 10;
set_of_features_to_try = [1, 7, 8, 9];
nRuns = 1;
classifierList = {@two_class_logreg};
subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');

% Looping over each subject and performing classification
for s = 6:nSubjects
	switch subject_ids{s}
	case 'P20_060', classes_to_classify = [5, 9; 5, 11]; % dosage vs exercise and dosage vs MPH
	case 'P20_061', classes_to_classify = [5, 9]; % dosage vs activity and dosage vs exercise
	case 'P20_079', classes_to_classify = [5, 13; 5, 10]; % dosage vs bike and dosage vs MPH
	case 'P20_053', classes_to_classify = [5, 8; 5, 10]; % dosage vs ping and dosage vs MPH
	case 'P20_094', classes_to_classify = [5, 9; 5, 15; 5, 10]; % dosage vs exercise, dosage vs exercise2 and dosage vs MPH
	end
	nAnalysis = size(classes_to_classify, 1);
	mean_over_runs = cell(1, nAnalysis);
	errorbars_over_runs = cell(1, nAnalysis);
	auc_over_runs = cell(1, nAnalysis);
	feature_str = cell(1, nAnalysis);
	class_label = cell(1, nAnalysis);
	bin_str = cell(1, nAnalysis);
	% Looping over each pair of classification tasks i.e. 1 vs 2, 1 vs 3, etc
	for c = 1:nAnalysis
		[mean_over_runs{1, c}, errorbars_over_runs{1, c}, auc_over_runs{1, c},...
		 feature_str{1, c}, class_label{1, c}, bin_str{1, c}] =...
				classify_ecg_data(subject_ids{s}, classes_to_classify(c, :),...
				set_of_features_to_try, nRuns, tr_percent, classifierList);
	end
	% Collecting the results to be plotted later
	classifier_results = struct();
	classifier_results.mean_over_runs = mean_over_runs;
	classifier_results.errorbars_over_runs = errorbars_over_runs;
	classifier_results.auc_over_runs = auc_over_runs;
	classifier_results.feature_str = feature_str;
	classifier_results.class_label = class_label;
	classifier_results.bin_str = bin_str;
	save(fullfile(result_dir, subject_ids{s}, sprintf('%s_classifier_hrbased_results_tr%d', subject_ids{s}, tr_percent)),...
							'-struct', 'classifier_results');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mean_over_runs, errorbars_over_runs, auc_over_runs, feature_str, class_label, bin_str] =...
			classify_ecg_data(subject_id, classes_to_classify, set_of_features_to_try, nRuns, tr_percent, classifierList)

if nargin ~= 6, error('Missing input arguments!'); end

nBin_size = 5;
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
cut_off_heart_rate = (1000 ./ (cut_off_heart_rate .* 4)) .* 60;
assert(length(cut_off_heart_rate) == 2);
hr_bins = [cut_off_heart_rate(2):nBin_size:cut_off_heart_rate(1)] + 1;
hr_bins(1) = cut_off_heart_rate(2);

nFeatures = length(set_of_features_to_try);
nClassifiers = numel(classifierList);
nClasses = length(classes_to_classify);
assert(nClasses == 2);

mean_over_runs = NaN(nFeatures, length(hr_bins)-1, nClassifiers);
errorbars_over_runs = NaN(nFeatures, length(hr_bins)-1, nClassifiers);
auc_over_runs = NaN(nFeatures, length(hr_bins)-1, nClassifiers);
class_label = cell(1, nClasses);
feature_str = cell(1, nFeatures);
bin_str = {};
loaded_data = [];

% Loop over each class in a two class problem and fetch the data instances x all features for each class (while respecting the session and dosage levels). Look at this as trimming the data matrix by only removing unnecessary rows
for c = 1:nClasses
	loaded_data = [loaded_data; massage_data(subject_id, classes_to_classify(c))];
	class_information = classifier_profile(classes_to_classify(c));
	class_label{1, c} = class_information{1, 1}.label;
end

for f = 1:nFeatures
	for b = 1:length(hr_bins)-1
		if f == 1
			bin_str{end+1} = sprintf('%d-%d', hr_bins(b), hr_bins(b+1)-1);
		end
		[complete_train_set, complete_test_set, feature_str{1, f}] = setup_data_matrix_based_on_hr(loaded_data,...
			set_of_features_to_try(f), tr_percent, [hr_bins(b), hr_bins(b+1)-1], class_label, subject_id, length(hr_bins)-1);
		accuracies = NaN(nRuns, nClassifiers);
		auc = NaN(nRuns, nClassifiers);
		if ~isempty(complete_train_set) & ~isempty(complete_test_set)
			for r = 1:nRuns
				for k = 1:nClassifiers
					[accuracies(r, k), junk, junk, auc(r, k)] =...
						classifierList{k}(complete_train_set, complete_test_set, '');
				end
			end
		else
			accuracies(1:nRuns, 1:nClassifiers) = 0;
			auc(1:nRuns, 1:nClassifiers) = 0;
		end
		assert(~isnan(accuracies(:)));
		assert(~isnan(auc(:)));
		mean_over_runs(f, b, :) = mean(accuracies, 1);
		errorbars_over_runs(f, b, :) = std(accuracies, [], 1) ./ nRuns;
		auc_over_runs(f, b, :) = mean(auc, 1);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[complete_train_set, complete_test_set, title_str] = setup_data_matrix_based_on_hr(loaded_data,...
						feature_set_flag, tr_percent, hr_bins, class_label, subject_id, nBins)

assert(length(hr_bins) == 2);
title_str = '';
complete_train_set = [];
complete_test_set = [];
final_labels = {-1, 1};

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
pt_peak_col = nInterpolatedFeatures + 2;
rt_peak_col = nInterpolatedFeatures + 3;
qt_peak_col = nInterpolatedFeatures + 4;
qtc_peak_col = nInterpolatedFeatures + 5;
pr_peak_col = nInterpolatedFeatures + 6;
qs_peak_col = nInterpolatedFeatures + 7;
p_height_col = nInterpolatedFeatures + 8;
q_height_col = nInterpolatedFeatures + 9;
r_height_col = nInterpolatedFeatures + 10;
s_height_col = nInterpolatedFeatures + 11;
t_height_col = nInterpolatedFeatures + 12;
dosage_col = nInterpolatedFeatures + 13;
expsess_col = nInterpolatedFeatures + 14;
label_col = nInterpolatedFeatures + 15;
cols_to_scale = '';

% computing the heart rates from RR
hr_est = (1000 ./ (loaded_data(:, rr_col) .* 4)) .* 60;
% classes to classify like 5, 9, etc
classes_to_classify = unique(loaded_data(:, label_col));
nClasses = length(classes_to_classify);

min_count = Inf;
% loop over all classes and find sample indices that fall within the given heart rate bin.
% Also find the absolute minimum number of samples, k, which qualify within each class
for c = 1:nClasses
	bin_idx{c} = find(hr_est >= hr_bins(1) & hr_est <= hr_bins(2) & loaded_data(:, label_col) == classes_to_classify(c));
	if min_count > length(bin_idx{c})
		min_count = length(bin_idx{c});
	end
end

switch feature_set_flag
case 1
	feature_cols = rr_col;
	title_str = 'RR';
case 7
	feature_cols = [qs_peak_col, pr_peak_col, qt_peak_col, qtc_peak_col, t_height_col];
	title_str = 'AM';
	cols_to_scale = 1:4;
case 8
	feature_cols = [qs_peak_col, pr_peak_col, qt_peak_col, qtc_peak_col];
	title_str = 'AM-T';
	cols_to_scale = 4;
case 9
	feature_cols = ecg_col;
	title_str = 'W';
otherwise
	error('Invalid feature set flag!');
end

if ~isempty(cols_to_scale)
	loaded_data(:, feature_cols) = scale_features(loaded_data(:, feature_cols), cols_to_scale);
end

% If the minimum sample count within each class exceeds 50 i.e. there are atleast k >= 50 samples within each class
if min_count > 50
	for c = 1:nClasses
		% Randomly sample k samples from the class which has greater than k samples i.e. downsampling and for the class
		% which has exactly k samples there is a random permutation
		rand_permutation = randperm(length(bin_idx{c}));
		bin_idx{c} = bin_idx{c}(rand_permutation(1:min_count));

		% Find a train, test partition (rows)
		temp_tr = round_to(tr_percent * length(bin_idx{c}) / 100, 0);
		train_samples = bin_idx{c}(1:temp_tr);
		test_samples = setdiff(bin_idx{c}, train_samples);
		assert(isempty(intersect(train_samples, test_samples)));

		% Build train and test set for both classes
		complete_train_set = [complete_train_set; loaded_data(train_samples, feature_cols),...
							repmat(final_labels{c}, length(train_samples), 1)];
		complete_test_set = [complete_test_set; loaded_data(test_samples, feature_cols),...
							repmat(final_labels{c}, length(test_samples), 1)];
		class_hr_to_plot{c} = hr_est([train_samples', test_samples']);
	end
	if feature_set_flag == 9
		plot_complexes_hr_bins(complete_train_set, complete_test_set, class_hr_to_plot, class_label, hr_bins, subject_id, nBins);
	end
end

