function[] = sparse_coding_plots(which_plot, varargin)

close all;

global plot_dir
plot_dir = get_project_settings('plots');
global results_dir
results_dir = get_project_settings('results');
global image_format
image_format = get_project_settings('image_format');
global window_size
window_size = 25;
global hr_str
hr_str = {'low', 'med.', 'high'};

switch which_plot
case 1, dist_bw_complexes();
case 2, dictionary_elements(varargin{:});
case 3, train_test_linear(varargin{:});
case 5, crf_features(varargin{:});
case 6, overlay_hr();
case 7, sparse_diff_hr();
case 8, overlay_sgram_hr();
case 4, confusion_mats(varargin{:});
case 9, three_confusion_mats(varargin{:});
case 10, data_cases(varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = data_cases(varargin)

global plot_dir;
global image_format;
global results_dir;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
legend_str = {'tr', 'corr.test', 'incorr.mul', 'incorr.crf', 'both incorr.'};
legend_entry = zeros(1, 5);

assert(length(varargin) == 10);
ecg_train = varargin{1};
ecg_train_Y = varargin{2};
ecg_test = varargin{3};
ecg_test_Y = varargin{4};
crf_predicted_label = varargin{5};
mul_predicted_label = varargin{6};
init_option = varargin{7};
variable_window = varargin{8};
win_str = 'fixed';
if variable_window, win_str = 'variable'; end
sparse_coding = varargin{9};
feat_str = 'peaks';
if sparse_coding, feat_str = 'sparse'; end
first_bl_subtract = varargin{10};

assert(size(ecg_train, 2) == size(ecg_train_Y, 2));
assert(size(ecg_test, 2) == size(ecg_test_Y, 2));
assert(length(ecg_test_Y) == length(crf_predicted_label));
assert(length(crf_predicted_label) == length(mul_predicted_label));

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
for i = 1:length(label_str)
	subplot(2, 3, i);
	train_idx = find(ecg_train_Y == i);
	if ~isempty(train_idx)
		h1 = plot(ecg_train(:, train_idx), 'r-'); hold on; grid on
		legend_entry(1) = h1(1);
	end
	both_grnd_idx = find(ecg_test_Y == i & crf_predicted_label == i & mul_predicted_label == i);
	if ~isempty(both_grnd_idx)
		h2 = plot(ecg_test(:, both_grnd_idx), 'b-');
		legend_entry(2) = h2(1);
	end
	crf_grnd_idx = find(ecg_test_Y == i & crf_predicted_label == i & mul_predicted_label ~= i);
	if ~isempty(crf_grnd_idx)
		h3 = plot(ecg_test(:, crf_grnd_idx), 'g-', 'linewidth', 2);
		legend_entry(3) = h3(1);
	end
	mul_grnd_idx = find(ecg_test_Y == i & crf_predicted_label ~= i & mul_predicted_label == i);
	if ~isempty(mul_grnd_idx)
		h4 = plot(ecg_test(:, mul_grnd_idx), 'm-', 'linewidth', 2);
		legend_entry(4) = h4(1);
	end
	only_grnd_idx = find(ecg_test_Y == i & crf_predicted_label ~= i & mul_predicted_label ~= i);
	if ~isempty(only_grnd_idx)
		h5 = plot(ecg_test(:, only_grnd_idx), 'k-', 'linewidth', 2);
		legend_entry(5) = h5(1);
	end
	xlabel('Windowed peaks'); ylabel('Millivolts'); xlim([1, 51]); grid on;
	% if first_bl_subtract, ylim([-0.1347, 0.1347]); 
	% else, ylim([2.2, 2.7]);
	% end
	title(sprintf('%s, %s, %s wave', feat_str, win_str, label_str{i}));
end
h100 = legend(legend_entry(legend_entry > 0), legend_str(legend_entry > 0));
set(h100, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/samples_train_test%d', plot_dir, init_option);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = three_confusion_mats(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 7);
mul_confusion_mat = varargin{1};
crf_confusion_mat = varargin{2};
avg_crf_log_likelihood = varargin{3};
init_option = varargin{4};
label_str = varargin{5};
variable_window = varargin{6};
win_str = 'fixed';
if variable_window, win_str = 'variable'; end
sparse_coding = varargin{7};
feat_str = 'peaks';
if sparse_coding, feat_str = 'sparse'; end

[x, y] = meshgrid(1:length(label_str)); %# Create x and y coordinates for the strings
figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
colormap bone;

total_error = ones(size(mul_confusion_mat)) - mul_confusion_mat;
total_error = sum(total_error(:));
subplot(2, 2, 1);
imagesc(mul_confusion_mat);
textStrings = strtrim(cellstr(num2str(mul_confusion_mat(:), '%0.4f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %# Plot the strings
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(mul_confusion_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
colorbar
title(sprintf('%s, %s, Multi. Log. regression, total error=%0.4f', feat_str, win_str, total_error));
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str);
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str);
if init_option <= 0, xlabel('Test'); ylabel('Train');
else, xlabel('Predicted'); ylabel('Ground');
end

total_error = ones(size(crf_confusion_mat)) - crf_confusion_mat;
total_error = sum(total_error(:));
subplot(2, 2, 2);
imagesc(crf_confusion_mat);
textStrings = strtrim(cellstr(num2str(crf_confusion_mat(:), '%0.4f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %# Plot the strings
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(crf_confusion_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
colorbar
title(sprintf('%s, %s, Basic CRF, total error=%0.4f', feat_str, win_str, total_error));
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str);
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str);
if init_option <= 0, xlabel('Test'); ylabel('Train');
else, xlabel('Predicted'); ylabel('Ground');
end

subplot(2, 2, 4);
imagesc(avg_crf_log_likelihood);
textStrings = strtrim(cellstr(num2str(avg_crf_log_likelihood(:), '%0.4f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %# Plot the strings
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(avg_crf_log_likelihood(:) < midValue, 1, 3);
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

file_name = sprintf('%s/sparse_coding/confusion_mat_init_%d', plot_dir, init_option);
savesamesize(gcf, 'file', file_name, 'format', image_format);
% saveas(gcf, file_name, 'pdf') % Save figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = confusion_mats(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 6);
mul_confusion_mat = varargin{1};
crf_confusion_mat = varargin{2};
init_option = varargin{3};
label_str = varargin{4};
variable_window = varargin{5};
win_str = 'fixed';
if variable_window, win_str = 'variable'; end
sparse_coding = varargin{6};
feat_str = 'peaks';
if sparse_coding, feat_str = 'sparse'; end

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
title(sprintf('%s, %s, Multinomial Log. regression', feat_str, win_str));
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
title(sprintf('%s, %s, Basic CRF', feat_str, win_str));
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str);
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str);
if init_option <= 0, xlabel('Test'); ylabel('Train');
else, xlabel('Predicted'); ylabel('Ground');
end

file_name = sprintf('%s/sparse_coding/confusion_mat_init_%d', plot_dir, init_option);
savesamesize(gcf, 'file', file_name, 'format', image_format);
% saveas(gcf, file_name, 'pdf') % Save figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = dist_bw_complexes()

global plot_dir;
global image_format;
global results_dir;
global window_size;
uniform_split = true;

subject_id = 'P20_040';
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));
% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);

% Picking out the peaks
peak_idx = labeled_peaks(2, :) > 0;
peak_idx(1:window_size) = 0;
peak_idx(end-window_size:end) = 0;

% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_sgram_061013.mat');
estimated_hr = ones(size(ecg_data)) * -1;
load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_big_sgram_061313.mat');
estimated_hr(peak_idx) = assigned_hr;

if uniform_split
	nBins = 3;
	tmp_valid_hr = estimated_hr(estimated_hr > 0);
	binned_hr = ntile_split(tmp_valid_hr, nBins);
	for b = 1:nBins
		hr_bins(b, :) = [min(tmp_valid_hr(binned_hr{b})), max(tmp_valid_hr(binned_hr{b}))];
	end
else
	hr_bins = [50, 99; 100, 119; 120, 1000];
end

% Picking out the labelled peaks
labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx(1:window_size) = 0;
labeled_idx(end-window_size:end) = 0;

labeled_peaks_idx = peak_idx & labeled_idx;

with_pr_dist = []; with_qr_dist = []; with_rs_dist = []; with_rt_dist = []; rr_plot = [];
acrs_pr_dist = []; acrs_qr_dist = []; acrs_rr_dist = []; acrs_rs_dist = []; acrs_rt_dist = [];
for hr1 = 1:size(hr_bins, 1)
	% Training instances. Finding which of the hand labelled peaks fall within the valid HR range
	tr_idx = estimated_hr >= hr_bins(hr1, 1) & estimated_hr <= hr_bins(hr1, 2);
	tr_idx = find(tr_idx & labeled_peaks_idx);
	train_clusters = find(diff(tr_idx) > 100);                     
	train_clusters = [1, train_clusters+1; train_clusters, length(tr_idx)];
	
	for t = 1:size(train_clusters, 2)
		ecg_data_idx = tr_idx(train_clusters(1, t):train_clusters(2, t));
		% train_hr = estimated_hr(ecg_data_idx);
		labels_in_cluster = labeled_peaks(3, ecg_data_idx);

		with_p_peak = -1; with_q_peak = -1; with_r_peak = -1; with_s_peak = -1; with_t_peak = -1;
		within_cluster = [];
		for l = 1:length(labels_in_cluster)
			switch labels_in_cluster(l)
			case 1, with_p_peak = l;
			case 2, with_q_peak = l;
			case 3, with_r_peak = l;
			case 4, with_s_peak = l;
			case 5
				with_t_peak = l;
				within_cluster = [within_cluster; with_p_peak, with_q_peak, with_r_peak, with_s_peak, with_t_peak];
				with_p_peak = -1; with_q_peak = -1; with_r_peak = -1; with_s_peak = -1; with_t_peak = -1;
			end
		end
		within_cluster = within_cluster(find(sum(within_cluster > 0, 2) == size(within_cluster, 2)), :);
		nClusters = size(within_cluster, 1);
		if nClusters > 1
			with_pr_dist = [with_pr_dist; (ecg_data_idx(within_cluster(:, 3)) - ecg_data_idx(within_cluster(:, 1)))'];
			with_qr_dist = [with_qr_dist; (ecg_data_idx(within_cluster(:, 3)) - ecg_data_idx(within_cluster(:, 2)))'];
			with_rs_dist = [with_rs_dist; (ecg_data_idx(within_cluster(:, 4)) - ecg_data_idx(within_cluster(:, 3)))'];
			with_rt_dist = [with_rt_dist; (ecg_data_idx(within_cluster(:, 5)) - ecg_data_idx(within_cluster(:, 3)))'];
			for n = 2:nClusters
				acrs_pr_dist = [acrs_pr_dist; ecg_data_idx(within_cluster(n, 1)) - ecg_data_idx(within_cluster(n-1, 3))];
				acrs_qr_dist = [acrs_qr_dist; ecg_data_idx(within_cluster(n, 2)) - ecg_data_idx(within_cluster(n-1, 3))];
				acrs_rr_dist = [acrs_rr_dist; ecg_data_idx(within_cluster(n, 3)) - ecg_data_idx(within_cluster(n-1, 3))];
				acrs_rs_dist = [acrs_rs_dist; ecg_data_idx(within_cluster(n, 4)) - ecg_data_idx(within_cluster(n-1, 3))];
				acrs_rt_dist = [acrs_rt_dist; ecg_data_idx(within_cluster(n, 5)) - ecg_data_idx(within_cluster(n-1, 3))];
				if n == nClusters
					rr_plot = [rr_plot, ecg_data_idx(within_cluster(n, 3)) - ecg_data_idx(within_cluster(n-1, 3)),...
							    ecg_data_idx(within_cluster(n, 3)) - ecg_data_idx(within_cluster(n-1, 3))];
				else
					rr_plot = [rr_plot, ecg_data_idx(within_cluster(n, 3)) - ecg_data_idx(within_cluster(n-1, 3))];
				end
			end
		end
	end
end

figure(); set(gcf, 'Position', [70, 10, 1200, 800]);
h1 = scatter(rr_plot, with_pr_dist, 'ro'); hold on; grid on; lsline;
h2 = scatter(rr_plot, with_qr_dist, 'go'); lsline;
h3 = scatter(rr_plot, with_rs_dist, 'bo'); lsline;
h4 = scatter(rr_plot, with_rt_dist, 'ko'); lsline;
h5 = scatter(acrs_rr_dist, acrs_pr_dist, 'r*'); lsline;
h6 = scatter(acrs_rr_dist, acrs_qr_dist, 'g*'); lsline;
h7 = scatter(acrs_rr_dist, acrs_rs_dist, 'b*'); lsline;
h8 = scatter(acrs_rr_dist, acrs_rt_dist, 'k*'); lsline;
xlabel('RR dist.'); ylabel('distances');
title(sprintf('Within and Across complex'));
legend([h1(1), h2(1), h3(1), h4(1), h5(1), h6(1), h7(1), h8(1)], 'with pr', 'with qr', 'with rs', 'with rt', 'acrs pr', 'acrs qr', 'acrs rs', 'acrs rt');

file_name = sprintf('%s/sparse_coding/misc_plots/rr_vs_dist', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = dictionary_elements(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 2);
param = varargin{1};
D = varargin{2};
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = train_test_linear(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 7);
ecg_sparse_feats = varargin{1};
peak_labels = varargin{2};
alpha = varargin{3};
D = varargin{4};
actual_idx = varargin{5};
label_str = varargin{6};

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

	file_name = sprintf('%s/sparse_coding/%s_lab%d', plot_dir, varargin{7}, tr);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = crf_features(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 4);
feature_params = varargin{1};
trans_params = varargin{2};
init_option = varargin{3};
D = varargin{4};
label_str = varargin{5};

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = overlay_sgram_hr()

global plot_dir;
global image_format;
global results_dir;
global window_size

subject_id = 'P20_040';
event = 1;
subject_profile = subject_profiles(subject_id);
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));
% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);
% Picking out the peaks
peak_idx = find(labeled_peaks(2, :) > 0);

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_behav_hr.mat', subject_id)));

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_sgram_061013.mat'));
sgram_based_hr = estimated_hr(estimated_hr > 0);

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_big_sgram_061313.mat'));
sgram_big_hr = assigned_hr;

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(sgram_based_hr, 'b-'); hold on;
plot(sgram_big_hr, 'r-');
plot(behav_hr(peak_idx), 'ko', 'MarkerFaceColor', 'k');

xlabel('peaks ONLY'); ylabel('heart rate');
legend('Sgram 0.6 min', 'Sgram 2 min', 'behav');
ylim([70, 150]);

file_name = sprintf('%s/sparse_coding/misc_plots/ovlp_sgram_hr', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = overlay_hr()

global plot_dir;
global image_format;
global results_dir;
global window_size

subject_id = 'P20_040';
event = 1;
subject_profile = subject_profiles(subject_id);
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));
% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);
% Picking out the peaks
peak_idx = find(labeled_peaks(2, :) > 0);
% Making sure a window can be drawn around the first and last peak
peak_idx = peak_idx(peak_idx > window_size & peak_idx <= size(labeled_peaks, 2)-window_size);

rr_based_hr = compute_hr('rr', ecg_data, peak_idx, subject_profile.events{event}.rr_thresholds);

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_behav_hr.mat', subject_id)));

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_fft_053013.mat'));
fft_based_hr = assigned_hr;

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_sgram_061013.mat'));
sgram_based_hr = estimated_hr(estimated_hr > 0);

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_big_sgram_061313.mat'));
sgram_big_hr = assigned_hr;

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(rr_based_hr, 'b.'); hold on;
plot(fft_based_hr, 'r-');
plot(sgram_based_hr, 'g-');
plot(sgram_big_hr, 'm-');
plot(behav_hr(peak_idx), 'ko', 'MarkerFaceColor', 'k');

xlabel('peaks ONLY'); ylabel('heart rate');
legend('RR based', 'FFT based', 'Sgram 0.6min', 'Sgram 2min', 'behav');
ylim([70, 150]);

file_name = sprintf('%s/sparse_coding/misc_plots/ovlp_all_hr', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = sparse_diff_hr()

global plot_dir;
global image_format;
global hr_str;
global results_dir;

label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

l = 97; m = 111; h = 132;
low = load(sprintf('%s/sparse_coding/reinterpolated_hr%d.mat', results_dir, l));
med = load(sprintf('%s/sparse_coding/reinterpolated_hr%d.mat', results_dir, m));
hig = load(sprintf('%s/sparse_coding/reinterpolated_hr%d.mat', results_dir, h));

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
for i = 1:length(label_str)
	subplot(2, 3, i);
	h1 = plot(low.before_ecg_low_hr{i}, 'r'); hold on;
	h2 = plot(med.before_ecg_med_hr{i}, 'g');
	h3 = plot(hig.before_ecg_hig_hr{i}, 'b');
	xlabel('Sparse Rep.'); ylabel('Millivolts');
	xlim([1, 51]); ylim([2.2, 2.7]); grid on;
	title(sprintf('orig, %s wave', label_str{i}));
end
h1 = legend([h1(1), h2(1), h3(3)], hr_str);
set(h1, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/before_rewin', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
for i = 1:length(label_str)
	subplot(2, 3, i);
	h1 = plot(low.after_ecg_low_hr{i}, 'r'); hold on;
	h2 = plot(med.after_ecg_med_hr{i}, 'g');
	h3 = plot(hig.after_ecg_hig_hr{i}, 'b');
	xlabel('Sparse Rep.'); ylabel('Millivolts');
	xlim([1, 51]); ylim([2.2, 2.7]); grid on;
	title(sprintf('resized, %s wave', label_str{i}));
end
h1 = legend([h1(1), h2(1), h3(3)], hr_str);
set(h1, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/after_rewin', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%{
figure();
plot(assigned_hr);
xlabel('samples');
ylabel('heart rate');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
file_name = sprintf('%s/sparse_coding/fft_window_%d', plot_dir, window_size);
savesamesize(gcf, 'file', file_name, 'format', image_format);
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

with_pr_dist = ecg_data_idx(with_r_peak) - ecg_data_idx(with_p_peak)
with_rt_dist = ecg_data_idx(with_t_peak) - ecg_data_idx(with_r_peak)
if labels_in_cluster(l) == 1 & acrs_p_peak < 0 & with_r_peak > 0
	acrs_p_peak = l;
	acrs_pr_dist = ecg_data_idx(with_r_peak) - ecg_data_idx(acrs_p_peak)
end
if labels_in_cluster(l) == 5 & acrs_t_peak < 0 & with_r_peak > 0
	acrs_t_peak = l;
	acrs_rt_dist = ecg_data_idx(acrs_t_peak) - ecg_data_idx(with_r_peak)
end
%}

