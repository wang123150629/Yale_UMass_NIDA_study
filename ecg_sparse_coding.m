function[] = ecg_sparse_coding()

close all;

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

subject_id = 'P20_040';
event = 1;
subject_profile = subject_profiles(subject_id);
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;

% old file : Only five peaks lebelled, unknown peaks assigned previous valid peaks' labels
% load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_temp3_labels.mat', subject_id)));

% New file : Six labels P, Q, R, S, T, U - Unknown
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));

window_size = 50;
nDictionayElements = 100;
nIterations = 1000;
lambda = 0.15;

R = sparse_coding_func(nDictionayElements, nIterations, lambda, window_size, labeled_peaks);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[R] = sparse_coding_func(nDictionayElements, nIterations, lambda, window_size, labeled_peaks)

tr_partition = 60;

% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);
% Picking out the peaks
peak_idx = find(labeled_peaks(2, :) > 0);
% Making sure a window can be drawn around the first and last peak
peak_idx = peak_idx(peak_idx > window_size/2 & peak_idx <= size(labeled_peaks, 2)-window_size/2);
% Picking out the labelled peaks
labeled_idx = find(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100);
% Making sure a window can be drawn around the first and last labelled peak
labeled_idx = labeled_idx(labeled_idx > window_size/2 & labeled_idx <= size(labeled_peaks, 2)-window_size/2);

% Permuting the labelled peaks
% perm_labeled_idx = labeled_idx(randperm(length(labeled_idx)));
% No permutation
perm_labeled_idx = labeled_idx;
tr_idx = perm_labeled_idx(1:floor(length(labeled_idx) * tr_partition / 100));
ts_idx = setdiff(perm_labeled_idx, tr_idx);
assert(length(labeled_idx) == length(tr_idx) + length(ts_idx));
assert(isempty(intersect(tr_idx, ts_idx)));

train_win_idx = [tr_idx - window_size/2; tr_idx + window_size/2-1];
train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size));
ecg_train = ecg_data(train_win_idx)';
ecg_train_Y = labeled_peaks(3, tr_idx);

test_win_idx = [ts_idx - window_size/2; ts_idx + window_size/2-1];
test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size));
ecg_test = ecg_data(test_win_idx)';
ecg_test_Y = labeled_peaks(3, ts_idx);

unlabeled_idx = setdiff(peak_idx, labeled_idx);
unlabeled_idx = [unlabeled_idx - window_size/2; unlabeled_idx + window_size/2-1];
unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size));
ecg_learn = ecg_data(unlabeled_idx)';

param.K = nDictionayElements;  % learns a dictionary with 100 elements
param.iter = nIterations;  % let us see what happens after 1000 iterations.
param.lambda = lambda;
param.numThreads = 4; % number of threads
param.batchsize = 400;
param.approx = 0;

D = mexTrainDL(ecg_learn, param);
param.mode = 2;
train_alpha = mexLasso(ecg_train, D, param);
R = mean(0.5*sum((ecg_train-D * train_alpha) .^ 2) + param.lambda * sum(abs(train_alpha)));
test_alpha = mexLasso(ecg_test, D, param);

if nDictionayElements == 100 & window_size == 50 & lambda == 0.15 & nIterations == 1000
	rr = 5; cc = 10;
	rs = 10; rc = 10;
	plot_dir = get_project_settings('plots');
	image_format = get_project_settings('image_format');
	% figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	figure(); set(gcf, 'Position', get_project_settings('figure_size'));
	colormap bone;
	for d = 1:param.K
		subaxis(rs, rc, d, 'Spacing', 0.01, 'Padding', 0.01, 'Margin', 0.01);
		plot(D(:, d), 'LineWidth', 2); hold on;
		axis tight;
		grid on;
		set(gca, 'XTick', []);
		set(gca, 'YTick', []);
	end
	file_name = sprintf('%s/sparse_coding/sparse_dict_elements', plot_dir);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end
% plot_labelled_peaks(ecg_train, labeled_peaks, train_alpha, D, labeled_idx)

multinomial_log_reg(train_alpha', ecg_train_Y', test_alpha', ecg_test_Y');

% crf_prop_up(tr_idx, ts_idx, train_alpha', ecg_train_Y', test_alpha', ecg_test_Y')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = crf_prop_up(tr_idx, ts_idx, ecg_train_X, ecg_train_Y, ecg_test_X, ecg_test_Y)

train_chunks = find(diff(tr_idx) > 100);
train_chunks = [1, train_chunks+1; train_chunks, length(tr_idx)];

test_chunks = find(diff(ts_idx) > 100);
test_chunks = [1, test_chunks+1; test_chunks, length(ts_idx)];

[feature_params, trans_params] = optimize_feat_trans_params(train_chunks, ecg_train_X, ecg_train_Y);

keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = multinomial_log_reg(ecg_train_X, ecg_train_Y, ecg_test_X, ecg_test_Y)

labels = unique(ecg_train_Y);
nClasses = length(labels);
nVars = size(ecg_train_X, 2);
options.Display = 1;

% Adding bias
ecg_train_X = [ones(size(ecg_train_X, 1), 1), ecg_train_X];
ecg_test_X = [ones(size(ecg_test_X, 1), 1), ecg_test_X];

funObj = @(W)SoftmaxLoss2(W, ecg_train_X, ecg_train_Y, nClasses);
lambda = 1e-4 * ones(nVars+1, nClasses-1);
lambda(1, :) = 0; % Don't penalize biases
wSoftmax = minFunc(@penalizedL2, zeros((nVars+1) * (nClasses-1), 1), options, funObj, lambda(:));
wSoftmax = reshape(wSoftmax, [nVars+1, nClasses-1]);
wSoftmax = [wSoftmax, zeros(nVars+1, 1)];

[junk, yhat] = max(ecg_train_X * wSoftmax, [], 2);
trainErr = sum(yhat ~= ecg_train_Y) / length(ecg_train_Y);

[junk, yhatt] = max(ecg_test_X * wSoftmax, [], 2);
testErr = sum(yhatt ~= ecg_test_Y) / length(ecg_test_Y);
confusionmat(ecg_test_Y, yhatt)

figure(); imagesc(confusionmat(ecg_test_Y, yhatt));
set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
set(gca, 'YTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
colorbar;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_labelled_peaks(ecg_lbl_feats, labeled_peaks, alpha, D, labeled_idx)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for tr = 1:size(ecg_lbl_feats, 2)
	top_dict_elements_plot = 10;

	switch labeled_peaks(3, labeled_idx(tr))
	case 1, title_str = sprintf('P wave');
	case 2, title_str = sprintf('Q wave');
	case 3, title_str = sprintf('R wave');
	case 4, title_str = sprintf('S wave');
	case 5, title_str = sprintf('T wave');
	otherwise, title_str = sprintf('Unknown');
	end

	target_dict_elements = find(alpha(:, tr));
	[junk, sorted_idx] = sort(alpha(target_dict_elements, tr), 'descend');
	target_dict_elements = target_dict_elements(sorted_idx);
	top_dict_elements_plot = min(top_dict_elements_plot, length(target_dict_elements));
	target_dict_elements = target_dict_elements(1:top_dict_elements_plot);

	figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	for d = 1:length(target_dict_elements)
		subplot(4, 5, d);
		plot(D(:, target_dict_elements(d)), 'g-', 'LineWidth', 2); hold on;
		xlim([1, length(D(:, target_dict_elements(d)))]);
		set(gca, 'XTick', []);
		set(gca, 'YTick', []);
		[junk, junk, val] = find(alpha(target_dict_elements(d), tr));
		title(sprintf('alpha=%0.4f', val));
	end

	subplot(4, 5, [11, 12, 16, 17]);
	plot(ecg_lbl_feats(:, tr), 'r-', 'LineWidth', 2); hold on;
	plot(D(:, target_dict_elements) * alpha(target_dict_elements, tr), 'g-');
	y_lim = get(gca, 'ylim');
	title(sprintf('Top 10 feats; %s', title_str));
	legend('Original', 'Sparse', 'Location', 'NorthWest');
	grid on;

	subplot(4, 5, [14, 15, 19, 20]);
	plot(ecg_lbl_feats(:, tr), 'r-', 'LineWidth', 2); hold on;
	plot(D * alpha(:, tr), 'g-');
	ylim([y_lim]);
	title(sprintf('All feats (%d); %s', length(find(alpha(:, tr))), title_str));
	grid on;

	file_name = sprintf('%s/sparse_coding/lab%d', plot_dir, tr);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

close all;

%{
switch param
case 1, param_vector = [10, 20, 30, 40, 50]; % window size
case 2, param_vector = [100, 150, 200];
case 3, param_vector = [100, 500, 1000];
case 4, param_vector = [0.01, 0.05, 0.10, 0.15];
end

display_str = NaN(length(nIterations), 5);
for a = 1:length(param_vector)
	switch param
	case 1, window_size = param_vector(a); % window size
	case 2, nDictionayElements = param_vector(a); % window size
	case 3, nIterations = param_vector(a); % window size
	case 4, lambda = param_vector(a); % window size
	end
	R = sparse_coding_func(nDictionayElements, nIterations, lambda, window_size, labeled_peaks);
	display_str(a, :) = [window_size, nDictionayElements, nIterations, lambda, R];
end

for a = 1:length(param_vector)
	fprintf('%d; %d; %d; %0.4f; %0.6f\n', display_str(a, 1), display_str(a, 2), display_str(a, 3), display_str(a, 4),...
					      display_str(a, 5));
end

tr_partition = 60;

ecg_data = labeled_peaks(1, :);

% Picking out the peaks and taking a window around them
peak_idx = find(labeled_peaks(2, :) > 0);
peak_idx = peak_idx(peak_idx > window_size/2 & peak_idx <= size(labeled_peaks, 2)-window_size/2);

% Picking out the labelled peaks and taking a window around them
labeled_idx = find(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100);
labeled_idx = labeled_idx(labeled_idx > window_size/2 & labeled_idx <= size(labeled_peaks, 2)-window_size/2);

% Picking out the unlabelled peaks
unlabeled_idx = setdiff(peak_idx, labeled_idx);
% Picking out the peaks and taking a window around them
perm_unlabeled_idx = unlabeled_idx(randperm(length(unlabeled_idx)));
tr_idx = perm_unlabeled_idx(1:round_to(length(unlabeled_idx) * tr_partition / 100, 0));
ts_idx = setdiff(perm_unlabeled_idx, tr_idx);
assert(length(unlabeled_idx) == length(tr_idx) + length(ts_idx));
assert(isempty(intersect(tr_idx, ts_idx)));

tr_feats_idx = [tr_idx - window_size/2; tr_idx + window_size/2-1];
tr_feats_idx = floor(linspaceNDim(tr_feats_idx(1, :), tr_feats_idx(2, :), window_size));
ecg_tr_feats = ecg_data(tr_feats_idx)';
% plot(ecg_tr_feats)

lbl_feats_idx = [labeled_idx - window_size/2; labeled_idx + window_size/2-1];
lbl_feats_idx = linspaceNDim(lbl_feats_idx(1, :), lbl_feats_idx(2, :), window_size);
ecg_lbl_feats = ecg_data(lbl_feats_idx)';
ecg_lbl_labels = labeled_peaks(3, labeled_idx);

param.K = nDictionayElements;  % learns a dictionary with 100 elements
param.iter = nIterations;  % let us see what happens after 1000 iterations.
param.numThreads = 4; % number of threads
param.batchsize = 400;
param.approx = 0;
param.lambda = lambda;

% ImD = displayPatches(D);
% imagesc(ImD); colormap('gray');
% GridImg = make_grid_image(D', 5, 10, 10, 10, 0.5);

%}
