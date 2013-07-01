function[] = sparse_coding(input_pipeline)

% sparse_coding('rr_only')
% sparse_coding('fft_only')

% sparse_coding('fft_rwin')
% sparse_coding('rr_rwin')

close all;

global pipeline
pipeline = input_pipeline;
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

global label_str
window_size = 25;
tr_partition = 50;
% hr_bins = [0, 80; 80, 100; 100, 120; 120, 1000];
hr_bins = [80, 100; 100, 120; 120, 1000];

% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);

% Picking out the peaks
peak_idx = find(labeled_peaks(2, :) > 0);
% Making sure a window can be drawn around the first and last peak
peak_idx = peak_idx(peak_idx > window_size & peak_idx <= size(labeled_peaks, 2)-window_size);
% Picking out the labelled peaks
labeled_idx = find(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100);
% Making sure a window can be drawn around the first and last labelled peak
labeled_idx = labeled_idx(labeled_idx > window_size & labeled_idx <= size(labeled_peaks, 2)-window_size);
% Finding which of those peaks are in fact hand labelled
[junk, labeled_peaks_idx, junk] = intersect(peak_idx, labeled_idx);, 

% Computing the HR for each of the peaks (NOTE: Now all peaks are associated with a HR; NOT just labelled peaks)
% assigned_hr = RR_based_hr(ecg_data', peak_idx, subject_profile.events{event}.rr_thresholds);
hr_rr_based = NaN(size(ecg_data));
hr_rr_based(peak_idx) = RR_based_hr(ecg_data', peak_idx, subject_profile.events{event}.rr_thresholds);

% assigned_hr = FFT_ovlp_based_hr(ecg_data, peak_idx);
load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_053013.mat');
hr_fft_based = NaN(size(ecg_data));
hr_fft_based(peak_idx) = assigned_hr;

mul_accuracy = NaN(size(hr_bins, 1), size(hr_bins, 1));
crf_accuracy = NaN(size(hr_bins, 1), size(hr_bins, 1));

for hr1 = 1:size(hr_bins, 1)
	% Training instances
	% Finding which of the hand labelled peaks fall within the valid HR range
	valid_tr_idx = assigned_hr(labeled_peaks_idx) >= hr_bins(hr1, 1) & assigned_hr(labeled_peaks_idx) < hr_bins(hr1, 2);
	% Retaining only those labelled peaks
	labeled_tr_idx = labeled_idx(labeled_peaks_idx & valid_tr_idx);
	% No permutation
	tr_idx = labeled_tr_idx(1:floor(length(labeled_tr_idx) * tr_partition / 100));
	for hr2 = 1:size(hr_bins, 1)
		init_option = str2num(sprintf('%d%d', hr1, hr2));
		% Testing instances
		% Finding which of the hand labelled peaks fall within the valid HR range
		valid_ts_idx = assigned_hr(labeled_peaks_idx) >= hr_bins(hr2, 1) & assigned_hr(labeled_peaks_idx) < hr_bins(hr2, 2);
		% Retaining only those labelled peaks
		labeled_ts_idx = labeled_idx(labeled_peaks_idx & valid_ts_idx);
		% No permutation
		ts_idx = labeled_ts_idx(floor(length(labeled_ts_idx) * tr_partition / 100)+1:end);

		assert(isempty(intersect(tr_idx, ts_idx)));

		fprintf('tr=%d, ts=%d, tr length=%d, actual=%d, ts length=%d, actual=%d\n', hr1, hr2, length(labeled_tr_idx),...
			length(tr_idx), length(labeled_ts_idx), length(ts_idx));

		[mul_accuracy(hr1, hr2), crf_accuracy(hr1, hr2)] = analyze_based_on_HR(tr_idx, ts_idx, peak_idx,...
			labeled_idx, window_size, labeled_peaks, ecg_data, init_option, hr_fft_based, hr_rr_based, pipeline);
	end
end

label_str = {'80--100', '100--120', '>120'};
plot_confusion_matrices(mul_accuracy, crf_accuracy, 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mul_accuracy, crf_accuracy] = analyze_based_on_HR(tr_idx, ts_idx, peak_idx,...
			labeled_idx, window_size, labeled_peaks, ecg_data, init_option, hr_fft_based, hr_rr_based, pipeline)

plot_fig = false;
global D
global label_str
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

nDictionayElements = 100;
nIterations = 1000;
lambda = 0.15;

train_win_idx = [tr_idx - window_size; tr_idx + window_size];
train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size*2+1));
ecg_train = ecg_data(train_win_idx)';
ecg_train_Y = labeled_peaks(3, tr_idx);
switch pipeline
	case 'fft_rwin'
		ecg_train = window_and_interpolate(ecg_train, floor(hr_fft_based(tr_idx)), floor(hr_fft_based(tr_idx)),...
							window_size, true, ecg_train_Y);
	case 'fft_only'
		ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, 2));
	case 'rr_rwin'
		ecg_train = window_and_interpolate(ecg_train, floor(hr_fft_based(tr_idx)), floor(hr_rr_based(tr_idx)),...
							window_size, true, ecg_train_Y);
	case 'rr_only'
		ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, 2));
	otherwise, error('Invalid option!');
end

test_win_idx = [ts_idx - window_size; ts_idx + window_size];
test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size*2+1));
ecg_test = ecg_data(test_win_idx)';
ecg_test_Y = labeled_peaks(3, ts_idx);
switch pipeline
	case 'fft_rwin'
		ecg_test = window_and_interpolate(ecg_test, floor(hr_fft_based(tr_idx)), floor(hr_fft_based(ts_idx)), window_size, false);
	case 'fft_only'
		ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, 2));
	case 'rr_rwin'
		ecg_test = window_and_interpolate(ecg_test, floor(hr_fft_based(tr_idx)), floor(hr_rr_based(ts_idx)), window_size, false);
	case 'rr_only'
		ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, 2));
	otherwise, error('Invalid option!');
end

unlabeled_idx = setdiff(peak_idx, labeled_idx);
unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
ecg_learn = ecg_data(unlabeled_idx)';
switch pipeline
	case 'fft_rwin'
		ecg_learn = window_and_interpolate(ecg_learn, floor(hr_fft_based(setdiff(peak_idx, labeled_idx))),...
					floor(hr_fft_based(setdiff(peak_idx, labeled_idx))), window_size, false);
	case 'fft_only'
		ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, 2));
	case 'rr_rwin'
		ecg_learn = window_and_interpolate(ecg_learn, floor(hr_fft_based(setdiff(peak_idx, labeled_idx))),...
					floor(hr_rr_based(setdiff(peak_idx, labeled_idx))), window_size, false);
	case 'rr_only'
		ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, 2));
	otherwise, error('Invalid option!');
end

param.K = nDictionayElements;  % learns a dictionary with 100 elements
param.iter = nIterations;  % let us see what happens after 1000 iterations
param.lambda = lambda;
param.numThreads = 4; % number of threads
param.batchsize = 400;
param.approx = 0;
param.verbose = false;

D = mexTrainDL(ecg_learn, param);
param.mode = 2;
train_alpha = mexLasso(ecg_train, D, param);
test_alpha = mexLasso(ecg_test, D, param);
% R = mean(0.5*sum((ecg_train-D * train_alpha) .^ 2) + param.lambda * sum(abs(train_alpha)));

if plot_fig
	plot_dir = get_project_settings('plots');
	image_format = get_project_settings('image_format');

	rs = 10; rc = 10;
	figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	for d = 1:param.K
		subaxis(rs, rc, d, 'Spacing', 0.01, 'Padding', 0.01, 'Margin', 0.01);
		plot(D(:, d), 'LineWidth', 2); hold on;
		axis tight; grid on;
		set(gca, 'XTick', []);
		set(gca, 'YTick', []);
	end
	file_name = sprintf('%s/sparse_coding/sparse_dict_elements', plot_dir);
	savesamesize(gcf, 'file', file_name, 'format', image_format);

	% Display only ten train and test samples
	plot_labelled_peaks(ecg_train(:, 1:10), labeled_peaks(3, :), train_alpha, D, tr_idx, 'tr');
	plot_labelled_peaks(ecg_test(:, 1:10), labeled_peaks(3, :), test_alpha, D, ts_idx, 'ts');
end

% perform six class classification using multinomial logistic regression
mul_confusion_mat = multinomial_log_reg(train_alpha', ecg_train_Y', test_alpha', ecg_test_Y');
mul_confusion_mat = bsxfun(@rdivide, mul_confusion_mat, sum(mul_confusion_mat, 2));
mul_accuracy = sum(diag(mul_confusion_mat));

% perform classification using basic CRF's 
crf_confusion_mat = basic_crf_classification(tr_idx, ts_idx, train_alpha', ecg_train_Y', test_alpha', ecg_test_Y', plot_fig, init_option);
crf_confusion_mat = bsxfun(@rdivide, crf_confusion_mat, sum(crf_confusion_mat, 2));
crf_accuracy = sum(diag(crf_confusion_mat));

plot_confusion_matrices(mul_confusion_mat, crf_confusion_mat, init_option);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat] = basic_crf_classification(tr_idx, ts_idx, ecg_train_X, ecg_train_Y, ecg_test_X, ecg_test_Y, plot_fig, init_option)

% The next two lines converts [1, 24, 31 ...] into [1, 25, 32, ... ; 24, 31, 45,...]
train_clusters = find(diff(tr_idx) > 100);
train_clusters = [1, train_clusters+1; train_clusters, length(tr_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_tr_cluster_idx = diff(train_clusters) > 1;
train_clusters = train_clusters(:, valid_tr_cluster_idx);

labels = unique(ecg_train_Y);
% optimize featue and transition parameters
[feature_params, trans_params] = optimize_feat_trans_params(train_clusters, ecg_train_X, ecg_train_Y, labels);

% plot_learned_features(exp(feature_params), exp(trans_params), init_option);

% These tell you where a cluster ends
test_clusters = find(diff(ts_idx) > 100);
% These give you the start and end points of a cluster
test_clusters = [1, test_clusters+1; test_clusters, length(ts_idx)];
% I am only choosing a cluster only if it has atleast 2 peaks
valid_ts_cluster_idx = diff(test_clusters) > 1;
test_clusters = test_clusters(:, valid_ts_cluster_idx);
nLabels = length(labels);

fprintf('nTrain=%d, nTest=%d\n', size(train_clusters, 2), size(test_clusters, 2)); 

[log_likelihood, all_unary_marginals, all_pairwise_marginals] =...
				sum_prdt_msg_passing(feature_params, trans_params, test_clusters, ecg_test_X, ecg_test_Y, nLabels);

nTestSamples = length(all_unary_marginals);
predicted_label = NaN(size(ecg_test_Y)); 
for t = 1:nTestSamples
	unary_marginals = all_unary_marginals{t};
	[junk, predicted_label(test_clusters(1, t):test_clusters(2, t), 1)] = max([unary_marginals{:}], [], 1);
end

confusion_mat = confusionmat(ecg_test_Y, predicted_label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[confusion_mat] = multinomial_log_reg(ecg_train_X, ecg_train_Y, ecg_test_X, ecg_test_Y)

labels = unique(ecg_train_Y);
nClasses = length(labels);
nVars = size(ecg_train_X, 2);
options.Display = 0;

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
confusion_mat = confusionmat(ecg_test_Y, yhatt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_labelled_peaks(ecg_sparse_feats, peak_labels, alpha, D, actual_idx, varargin)

global label_str;

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for tr = 1:size(ecg_sparse_feats, 2)
	top_dict_elements_plot = 10;

	title_str = sprintf('%s wave', label_str{peak_labels(actual_idx(tr))});

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
	plot(ecg_sparse_feats(:, tr), 'r-', 'LineWidth', 2); hold on;
	plot(D(:, target_dict_elements) * alpha(target_dict_elements, tr), 'g-');
	y_lim = get(gca, 'ylim');
	title(sprintf('Top 10 feats; %s', title_str));
	legend('Original', 'Sparse', 'Location', 'NorthWest');
	grid on;

	subplot(4, 5, [14, 15, 19, 20]);
	plot(ecg_sparse_feats(:, tr), 'r-', 'LineWidth', 2); hold on;
	plot(D * alpha(:, tr), 'g-');
	ylim([y_lim]);
	title(sprintf('All feats (%d); %s', length(find(alpha(:, tr))), title_str));
	grid on;

	file_name = sprintf('%s/sparse_coding/%s_lab%d', plot_dir, varargin{1}, tr);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_confusion_matrices(mul_confusion_mat, crf_confusion_mat, init_option)

global label_str;
global pipeline;

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

[x, y] = meshgrid(1:length(label_str)); %# Create x and y coordinates for the strings
figure('visible', 'off'); set(gcf, 'Position', [70, 10, 1200, 500]);
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
colormap bone;

subplot(1, 2, 1);
imagesc(mul_confusion_mat);
textStrings = strtrim(cellstr(num2str(mul_confusion_mat(:), '%0.2f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %# Plot the strings
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(mul_confusion_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
colorbar
title('Multinomial Log. regression');
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str);
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str);
if init_option <= 0, xlabel('Test'); ylabel('Train');
else, xlabel('Predicted'); ylabel('Ground');
end

subplot(1, 2, 2);
imagesc(crf_confusion_mat);
textStrings = strtrim(cellstr(num2str(crf_confusion_mat(:), '%0.2f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %# Plot the strings
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(crf_confusion_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
colorbar
title('Basic CRF');
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str);
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str);
if init_option <= 0, xlabel('Test'); ylabel('Train');
else, xlabel('Predicted'); ylabel('Ground');
end

file_name = sprintf('%s/sparse_coding/confusion_mat_init_%d_%s', plot_dir, init_option, pipeline);
savesamesize(gcf, 'file', file_name, 'format', image_format);
% saveas(gcf, file_name, 'pdf') % Save figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_learned_features(feature_params, trans_params, init_option)

global D;
global label_str;

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

% feature_params = bsxfun(@rdivide, feature_params, sum(feature_params, 2));
figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
for f = 1:size(feature_params, 1)
	subplot(2, 3, f); plot(D * feature_params(f, :)', 'b-', 'LineWidth', 2);
	title(sprintf('Learned %s wave', label_str{f}));
	grid on;
end
file_name = sprintf('%s/sparse_coding/feat_pot_init_%d', plot_dir, init_option);
savesamesize(gcf, 'file', file_name, 'format', image_format);
% saveas(gcf, file_name, 'pdf') % Save figure

figure('visible', 'off'); set(gcf, 'Position', [70, 50, 600, 500]);
set(gcf, 'PaperPosition', [0 0 4 4]);
set(gcf, 'PaperSize', [4 4]);
colormap bone;
imagesc(trans_params);
set(gca, 'XTickLabel', label_str);
set(gca, 'YTickLabel', label_str);
colorbar
file_name = sprintf('%s/sparse_coding/trans_pot_init_%d', plot_dir, init_option);
savesamesize(gcf, 'file', file_name, 'format', image_format);
% saveas(gcf, file_name, 'pdf') % Save figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[ecg_samples] = window_and_interpolate(ecg_samples, hr_to_idx, hr_to_resize, window_size, plot_fig, varargin)

global pipeline;
global label_str;
results_dir = get_project_settings('results');

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
varying_windows = ceil(linspace(50, 35, 100));
hr_range = floor(linspace(50, 150, 100));
mid_point = floor(window_size+1);
assert(isequal(size(ecg_samples, 2), size(hr_to_resize, 2)));

if ~isempty(varargin)
	reinterpolated = struct();
	for i = 1:length(label_str)
		idx1 = find(varargin{1} == i & hr_to_idx >= 80 & hr_to_idx < 100);
		idx2 = find(varargin{1} == i & hr_to_idx >= 100 & hr_to_idx < 120);
		idx3 = find(varargin{1} == i & hr_to_idx >= 120);
		reinterpolated.before_ecg_low_hr{i} = ecg_samples(:, idx1);
		reinterpolated.before_ecg_med_hr{i} = ecg_samples(:, idx2);
		reinterpolated.before_ecg_hig_hr{i} = ecg_samples(:, idx3);
	end
end

for i = 1:size(hr_to_resize, 2)
	varying_window_entry = varying_windows(find(hr_range == hr_to_resize(i)));
	one_half = floor(varying_window_entry/2);
	% if mod(varying_window_entry, 2), plus_half = floor(varying_window_entry/2);
	% else, plus_half = floor(varying_window_entry/2)-1;
	% end
	new_window = mid_point-one_half:mid_point+one_half;
	new_wini = linspace(1, length(new_window), window_size*2+1);
	if i <= 5 & plot_fig
		figure('visible', 'off');
		set(gcf, 'Position', [100, 500, 1200, 600]);
		subplot(1, 2, 1); plot(ecg_samples(:, i)); title(sprintf('Before %s peak, win length=%d, hr=%d',...
			label_str{varargin{1}(i)}, window_size*2+1, hr_to_resize(i)));
		hold on; plot(new_window, ecg_samples(new_window, i), 'r');
		grid on; xlim([1, window_size*2+1]);
		plot(mid_point, ecg_samples(mid_point, i), 'k*');
	end
	ecg_samples(:, i) = interp1(1:length(new_window), ecg_samples(new_window, i), new_wini, 'pchip');
	if i <= 5 & plot_fig
		subplot(1, 2, 2); plot(ecg_samples(:, i)); title(sprintf('After, win length=%d', varying_window_entry));
		grid on; xlim([1, window_size*2+1]);
		file_name = sprintf('%s/sparse_coding/new_win_effect_hr%d_%d_%s', plot_dir, hr_to_resize(i), i, pipeline);
		savesamesize(gcf, 'file', file_name, 'format', image_format);
	end
end

ecg_samples = bsxfun(@minus, ecg_samples, mean(ecg_samples, 2));

if ~isempty(varargin)
	for i = 1:6
		idx1 = find(varargin{1} == i & hr_to_idx >= 80 & hr_to_idx < 100);
		idx2 = find(varargin{1} == i & hr_to_idx >= 100 & hr_to_idx < 120);
		idx3 = find(varargin{1} == i & hr_to_idx >= 120);
		reinterpolated.after_ecg_low_hr{i} = ecg_samples(:, idx1);
		reinterpolated.after_ecg_med_hr{i} = ecg_samples(:, idx2);
		reinterpolated.after_ecg_hig_hr{i} = ecg_samples(:, idx3);
	end
	save(sprintf('%s/sparse_coding/reinterpolated_hr%d_%s', results_dir, max(hr_to_idx), pipeline), '-struct', 'reinterpolated');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = RR_based_hr(ecg_data, peak_idx, rr_thresholds)

raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');

assigned_hr = NaN(size(peak_idx));

[rr, rs] = rrextract(ecg_data, raw_ecg_mat_time_res, rr_thresholds);
rr_start_end = [rr(1:end-1); rr(2:end)-1]';

% Assigning HR for the first chunk prior to the first R peak
rr_intervals = length(rr_start_end(1, 1):rr_start_end(1, 2));
heart_rate = (1000 * 60) ./ (4 .* rr_intervals);
assigned_hr(find(peak_idx < rr_start_end(1, 1))) = heart_rate;
% Assigning HR for all valid chunks
for r = 1:size(rr_start_end, 1)
	rr_intervals = length(rr_start_end(r, 1):rr_start_end(r, 2));
	% If valid RR interval then compute HR; if not then assign previous HR
	if rr_intervals >= 100 & rr_intervals <= 300
		heart_rate = (1000 * 60) ./ (4 .* rr_intervals);
	end
	assigned_hr(find(peak_idx >= rr_start_end(r, 1) & peak_idx < rr_start_end(r, 2))) = heart_rate;
end
% Assigning HR for the last chunk after the last R peak
assigned_hr(find(peak_idx >= rr_start_end(end, 2))) = heart_rate;

assert(~any(isnan(assigned_hr(:))));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = FFT_ovlp_based_hr(ecg_data, peak_idx)

assigned_hr = NaN(size(peak_idx));
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
window_size = 5 * 60 * raw_ecg_mat_time_res;
filter_size = 1000;
% h = fspecial('average', [1, filter_size]);
h = fspecial('gaussian', [1, filter_size], 150);

NFFT = 2 ^ nextpow2(window_size);
frequencies = (double(raw_ecg_mat_time_res) / 2 * linspace(0, 1, NFFT / 2)); % Vector containing frequencies in Hz
idx = frequencies * 60 >= 50 & frequencies * 60 <= 150;

for p = 1:length(peak_idx)
	start_win = peak_idx(p) - window_size/2;
	end_win = peak_idx(p) + window_size/2-1;
	if start_win < 0, start_win = 1; end
	if end_win > size(ecg_data, 2), end_win = size(ecg_data, 2); end

	win_data = ecg_data(start_win:end_win);
	Mdata = win_data - conv(win_data, h, 'same');
	Mdata = Mdata(filter_size/2:end-filter_size/2);
	Y = fft(double(Mdata), NFFT) / length(Mdata);
	amplitudes = 2 * abs(Y(1:(NFFT / 2))); % Vector containing corresponding amplitudes

	[max_a, max_frequency] = max(amplitudes(2:end)); % fetching the index of the maximum amplitude
	heart_rate = frequencies(max_frequency + 1) * 60;
	[max_r, max_freq_range] = max(amplitudes .* idx);
	if max_r/max_a > 0.5
		heart_rate = frequencies(max_freq_range + 1) * 60;
	end
	assigned_hr(p) = heart_rate;
end

%{
figure();
plot(assigned_hr);
xlabel('samples');
ylabel('heart rate');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
file_name = sprintf('%s/sparse_coding/fft_window_%d', plot_dir, window_size);
savesamesize(gcf, 'file', file_name, 'format', image_format);
keyboard
%}

%{
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
rr_assigned_hr = RR_based_hr(ecg_data', peak_idx, subject_profile.events{event}.rr_thresholds);
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(rr_assigned_hr);
hold on; plot(assigned_hr, 'r-', 'LineWidth', 2);
xlabel('peaks only'); ylabel('heart rate');
legend('RR based HR', 'FFT based HR');
file_name = sprintf('%s/sparse_coding/rr_ff_ovlp', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

temp = zeros(size(ecg_data));
temp(labeled_idx) = 1;
idx = find(~isnan(hr_fft_based));
temp(idx) = temp(idx) .* hr_fft_based(idx);
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(hr_fft_based(idx), 'r-');
hold on; plot(temp(idx), 'b*');
plot(1:length(idx), repmat(100, 1, length(idx)), 'k-');
plot(1:length(idx), repmat(120, 1, length(idx)), 'k-');
ylim([70, 150]);
xlim([0, length(idx)]);
file_name = sprintf('%s/sparse_coding/lab_pks_by_hr', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);
keyboard
%}

