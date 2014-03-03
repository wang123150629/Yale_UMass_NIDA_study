function[] = general_wrapper()

% general_wrapper()

% super_analysis_id = {'1402171'};
% subject_id = {'P20_040'};

super_analysis_id = {'1403021', '1403022'};
subject_id = {'P20_040' , '16773_atr'};

assert(numel(super_analysis_id) == numel(subject_id));
for s = 1:numel(subject_id)
	analysis_per_subject(subject_id{s}, super_analysis_id{s});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = analysis_per_subject(subject_id, super_analysis_id)

plot_dir = get_project_settings('plots');
results_dir = get_project_settings('results');

dispf('subject=%s', subject_id);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get statistics on clusters for each subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
peak_counts(subject_id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regular analysis pick best of 6 pipelines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analysis_id = sprintf('%sa', super_analysis_id);
label_ecg_peaks_wrapper(analysis_id, subject_id);

analysis_id = sprintf('%sb', super_analysis_id);
label_ecg_peaks_wrapper(analysis_id, subject_id, 'interintra');

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perf as a function of k-fold cross validation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analysis_id = sprintf('%sx', super_analysis_id);
assert(length(analysis_id) >= 7);
if ~exist(fullfile(plot_dir, 'sparse_coding', analysis_id))
	mkdir(fullfile(plot_dir, 'sparse_coding', analysis_id));
end

k_fold = 10;
filter_size = get_project_settings('filter_size');
clusters_apart = get_project_settings('clusters_apart');
cluster_partition = 3;

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
clear time_matrix;
switch subject_id
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', subject_id);
	labeled_peaks = labeled_peaks(:, magic_idx);
end
peak_idx = labeled_peaks(3, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = peak_idx & labeled_idx;
valid_peak_idx = find(labeled_peaks_idx);
valid_clusters = [0, find(diff(valid_peak_idx) > clusters_apart)];

nClusters_per_fold = repmat(floor(length(valid_clusters) / k_fold), 1, k_fold);
remainder = length(valid_clusters) - sum(nClusters_per_fold);
nClusters_per_fold(1:remainder) = nClusters_per_fold(1:remainder) + 1;
assert(length(valid_clusters) == sum(nClusters_per_fold));
nClusters_per_fold = [0, cumsum(nClusters_per_fold)];

ordered_valid_clusters = randperm(length(valid_clusters));
clusters_within_bins = {};
train_set = {};
validation_set = {};
test_set = {};
% Note: I randomly assign clusters to bins such that there are nearly uniform (11, 11, ... 10) number of clusters per bin. Following this
% we partition the k bins in the first fold as train - 1:3, validate 4:6, test 7:10, second fold as train - 2:4, validate 5:7, test 8:10, 1
% this repeated 10 folds
for k = 1:length(nClusters_per_fold)-1
	clusters_within_bins{k} = ordered_valid_clusters(nClusters_per_fold(k)+1:nClusters_per_fold(k+1));
	shifted_clusters = circshift([1:k_fold]', k);
	train_set{k} = shifted_clusters(1:3);
	validation_set{k} = shifted_clusters(4:6);
	test_set{k} = shifted_clusters(7:10);
end
cross_validation = struct();
cross_validation.clusters_within_bins = clusters_within_bins;
cross_validation.train_set = train_set;
cross_validation.validate_set = validation_set;
cross_validation.test_set = test_set;
cross_validation.which_fold = 1;
save(sprintf('%s/sparse_coding/%s/%s_cross_validation.mat', plot_dir, analysis_id, analysis_id), '-struct', 'cross_validation');

mul_confusion_mat = {};
matching_confusion_mat = {};
crf_confusion_mat = {};
crf_validate_errors = {};
mul_validate_errors = {};
for m = 1:k_fold
	dispf('>>>>>>>> fold %d <<<<<<<\n', m);
	[mul_confusion_mat{m}, matching_confusion_mat{m}, crf_confusion_mat{m},...
		crf_validate_errors{m}, mul_validate_errors{m}] = label_ecg_peaks_wrapper(analysis_id, subject_id, '', 3);
end
results = struct();
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.crf_validate_errors = crf_validate_errors;
results.mul_validate_errors = mul_validate_errors;
results.subject_id = subject_id;
gresults.k_fold = k_fold;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

general_wrapper_plots(4, analysis_id);
%}

%=============================================================================================================
%=============================================================================================================
%=============================================================================================================

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perf as a function of matching size window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
matching_pm = 1:10;
analysis_id = sprintf('%sy', super_analysis_id);
mul_confusion_mat = {};
matching_confusion_mat = {};
crf_confusion_mat = {};
for m = 1:length(matching_pm)
	[mul_confusion_mat{m}, matching_confusion_mat{m}, crf_confusion_mat{m}] =...
			label_ecg_peaks_wrapper(analysis_id, subject_id, 1, matching_pm(m));
end
results = struct();
results.matching_pm = matching_pm;
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.subject_id = subject_id;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perf as a function of random partition (NOT CROSS VALIDATION)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
runs = 1:10;
analysis_id = sprintf('%sz', super_analysis_id);
mul_confusion_mat = {};
matching_confusion_mat = {};
crf_confusion_mat = {};
for r = 1:length(runs)
	[mul_confusion_mat{r}, matching_confusion_mat{r}, crf_confusion_mat{r}] =...
			label_ecg_peaks_wrapper(analysis_id, subject_id, 2);
end
results = struct();
results.runs = runs;
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.subject_id = subject_id;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

%}

