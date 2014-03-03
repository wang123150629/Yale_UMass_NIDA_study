function[] = ecg_label_misc_plots(which_plot, varargin)

close all;

global plot_dir
plot_dir = get_project_settings('plots');
global results_dir
results_dir = get_project_settings('results');
global image_format
image_format = get_project_settings('image_format');
% image_format = 'pdf';
global window_size
window_size = 25;
global hr_str
hr_str = {'low', 'med.', 'high'};

switch which_plot
case 2, dictionary_elements(varargin{:});
case 3, plot_orig_recon(varargin{:});
case 4, two_confusion_mats(varargin{:});
case 9, summ_confusion_mats(varargin{:});
case 14, orig_recon_diff(varargin{:});
case 15, preprocess_ribbons(varargin{:});
case 16, gen_set_labels(varargin{:});
case 17, print_confusion_mats(varargin{:});
case 18, make_slack_plots(varargin{:});
%{
case 1, dist_bw_complexes();
case 3, train_test_linear(varargin{:});
case 5, crf_features(varargin{:});
case 6, overlay_hr();
case 7, sparse_diff_hr();
case 8, overlay_sgram_hr();
case 10, data_cases(varargin{:});
case 11, function_of_lambda(varargin{:});
case 12, sparse_heat_maps(varargin{:});
case 13, incorrect_sample_time_series(varargin{:});
%}
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_slack_plots(varargin)

global plot_dir;
global image_format;

labels_A = varargin{1};
labels_B = varargin{2};
matching_pm = varargin{3};
disp_flag = varargin{4};
legend_str = varargin{5};
xlabel_str = varargin{6};
record_no = varargin{7};
analysis_id = varargin{8};

b_entries = length(labels_B);
labels_B_idx = find(labels_B);
labels_B_only = labels_B(labels_B_idx);
nLabels = length(unique(labels_B_only));
assert(matching_pm > 0);
switch xlabel_str
case 'Predictions', tit_str = 'Precision';
case 'Ground-truth', tit_str = 'Recall';
otherwise, error('Invalid X label string!');
end
slack_range = -1 * matching_pm:matching_pm;
slack_results = NaN(length(slack_range), nLabels);

for s = 1:length(slack_range)
	best_match = [];
	% checking if shifting by slack variable is causing the indexing to go out of bounds. For eg. 5000 - 4 = 4996 which is > 1
	assert(min(labels_B_idx+slack_range(s)) >= 1 & max(labels_B_idx+slack_range(s)) <= b_entries);
	shifted_labels_B = zeros(1, b_entries);
	assert(isequal(length(labels_B_idx), length(labels_B_only)));
	shifted_labels_B(labels_B_idx+slack_range(s)) = labels_B_only;

	best_match = matching_driver(labels_A, shifted_labels_B, matching_pm, nLabels, disp_flag);
	if slack_range(s) == 0
		temp = confusionmat(labels_A(find(labels_A)), labels_B_only);
		assert(isequal(best_match, temp));
	end

	best_match = bsxfun(@rdivide, best_match, sum(best_match, 2));
	slack_results(s, :) = diag(best_match);
end
assert(all(~isnan(slack_results(:))));

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(slack_results, 'o-', 'LineWidth', 2);
grid on;
xlabel(sprintf('%s offset by', xlabel_str));
ylabel('Accuracy'); ylim([min(slack_results(:)) - 0.01, 1]);
title(sprintf('%s, Record %s', tit_str, get_project_settings('strrep_subj_id', record_no)));
set(gca, 'XTick', 1:length(slack_range));
set(gca, 'XTickLabel', slack_range);
legend(legend_str, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
xlim([1, length(slack_range)]);

file_name = fullfile(plot_dir, 'sparse_coding', 'slack', sprintf('%s_%s_%s_peaks', analysis_id, record_no,...
			get_project_settings('strrep_subj_id', xlabel_str)));
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = print_confusion_mats(varargin)

global plot_dir;
global image_format;

title_str = varargin{1};
analysis_id = varargin{2};
offset = 2;
nMatrices = length(varargin(offset+1:end));

label_str1 = {'P', 'Q', 'R', 'S', 'T', 'U'};
label_str2 = {'P', 'Q', 'R', 'S', 'T', 'Upq', 'Ust', 'Utp'};
label_str3 = {'P', 'Q', 'R', 'S', 'T', 'Uw', 'Ua'};
label_str4 = {'P', 'QRS', 'T', 'U'};

font_size = get_project_settings('font_size');
tl_fs = font_size(6);

ylim_l = Inf;
ylim_u = -Inf;
for m = 1:nMatrices
	if ylim_l > min(varargin{offset+m}(:))
		ylim_l = min(varargin{offset+m}(:));
	end
	if ylim_u < max(varargin{offset+m}(:))
		ylim_u = max(varargin{offset+m}(:));
	end
end

figure('visible', 'on'); set(gcf, 'Position', get_project_settings('figure_size'));
% set(gcf, 'PaperPosition', [0 0 6 4]);
% set(gcf, 'PaperSize', [6 4]);
colormap bone;

for i = 1:nMatrices
	switch size(varargin{i+offset}, 1)
	case 6, label_str = label_str1;
	case 8, label_str = label_str2;
	case 7, label_str = label_str3;
	case 4, label_str = label_str4;
	otherwise, error('Invalid number of labels!');
	end
	[x, y] = meshgrid(1:length(label_str)); %# Create x and y coordinates for the strings

	subplot(2, 2, i);
	fancy_write_out_mat(varargin{i+offset}, x, y, ylim_l, ylim_u, label_str)
	title(title_str{i}, 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
end

file_name = sprintf('%s/sparse_coding/%s/comp_conf_mats', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = fancy_write_out_mat(A, x, y, ylim_l, ylim_u, label_str)

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

imagesc(A);
textStrings = strtrim(cellstr(num2str(A(:), '%0.2f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(A(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
% h = colorbar;
% set(h, 'ylim', [ylim_l, ylim_u]);

set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = orig_recon_diff(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

ecg_test_originals = varargin{1};
ecg_test_reconstructions = varargin{2};
ecg_test_Y = varargin{3};
crf_predicted_label = varargin{4};
analysis_id = varargin{5};

for l = 1:length(label_str)
	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));

	idx1 = ecg_test_Y == l & ecg_test_Y == crf_predicted_label;

	corr_recon_peaks = ecg_test_reconstructions(idx1, :);
	x_final1 = 1:size(corr_recon_peaks, 2);
	y_final1 = mean(corr_recon_peaks, 1);
	interval1 = [y_final1 - std(corr_recon_peaks, [], 1); y_final1 + std(corr_recon_peaks, [], 1)];
	
	corr_orig_peaks = ecg_test_originals(idx1, :);
	x_final2 = 1:size(corr_orig_peaks, 2);
	y_final2 = mean(corr_orig_peaks, 1);
	interval2 = [y_final2 - std(corr_orig_peaks, [], 1); y_final2 + std(corr_orig_peaks, [], 1)];
	
	idx2 = ecg_test_Y == l & ecg_test_Y ~= crf_predicted_label;

	incor_recon_peaks = ecg_test_reconstructions(idx2, :);
	x_final3 = 1:size(incor_recon_peaks, 2);
	y_final3 = mean(incor_recon_peaks, 1);
	interval3 = [y_final3 - std(incor_recon_peaks, [], 1); y_final3 + std(incor_recon_peaks, [], 1)];

	incor_orig_peaks = ecg_test_originals(idx2, :);
	x_final4 = 1:size(incor_orig_peaks, 2);
	y_final4 = mean(incor_orig_peaks, 1);
	interval4 = [y_final4 - std(incor_orig_peaks, [], 1); y_final4 + std(incor_orig_peaks, [], 1)];
	
	ymin = min([min(interval1(:)), min(interval2(:)), min(interval3(:)), min(interval4(:))]);
	ymax = max([max(interval1(:)), max(interval2(:)), max(interval3(:)), max(interval4(:))]);

	subplot(2, 2, 1); plot(x_final1, y_final1, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final1, interval1(1, :), interval1(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('std. millivolts'); xlim([1, length(x_final1)]); ylim([ymin, ymax]);
	title(sprintf('Correct, reconstructed %s peaks(%d samples)', label_str{l}, sum(idx1)));

	subplot(2, 2, 2); plot(x_final2, y_final2, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final2, interval2(1, :), interval2(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('std. millivolts'); xlim([1, length(x_final2)]); ylim([ymin, ymax]);
	title(sprintf('Correct, original %s peaks(%d samples)', label_str{l}, sum(idx1)));

	if sum(idx2) > 0
		subplot(2, 2, 3); plot(x_final3, y_final3, 'b-', 'LineWidth', 2); hold on; grid on;
		color = [89, 89, 89] ./ 255; transparency = 0.4;
		hhh = jbfill(x_final3, interval3(1, :), interval3(2, :), color, rand(1, 3), 0, transparency);
		hAnnotation = get(hhh, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('windowed peaks'); ylabel('std. millivolts'); xlim([1, length(x_final3)]); ylim([ymin, ymax]);
		title(sprintf('Incorrect, reconstructed %s peaks(%d samples)', label_str{l}, sum(idx2)));

		subplot(2, 2, 4); plot(x_final4, y_final4, 'b-', 'LineWidth', 2); hold on; grid on;
		color = [89, 89, 89] ./ 255; transparency = 0.4;
		hhh = jbfill(x_final4, interval4(1, :), interval4(2, :), color, rand(1, 3), 0, transparency);
		hAnnotation = get(hhh, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('windowed peaks'); ylabel('std. millivolts'); xlim([1, length(x_final4)]); ylim([ymin, ymax]);
		title(sprintf('Incorrect, original %s peaks(%d samples)', label_str{l}, sum(idx2)));
	end
	file_name = sprintf('%s/sparse_coding/%s/ribbon_%speak', plot_dir, analysis_id, label_str{l});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = summ_confusion_mats(varargin)

global plot_dir;
global image_format;

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

assert(length(varargin) == 7);
mul_summary_mat = varargin{1};
mul_accuracy = round_to(mean(mul_summary_mat(:)), 2);
crf_summary_mat = varargin{2};
crf_accuracy = round_to(mean(crf_summary_mat(:)), 2);
mul_total_errors = varargin{3};
crf_total_errors = varargin{4};
ylim_l = min([min(mul_summary_mat(:)), min(crf_summary_mat(:))]);
ylim_u = max([max(mul_summary_mat(:)), max(crf_summary_mat(:))]);
hr_bins = varargin{5};
for b = 1:size(hr_bins, 1)
	hr_str{b} = sprintf('%d--%d', floor(min(hr_bins(b, 1))), floor(max(hr_bins(b, 2))));
end
[x, y] = meshgrid(1:length(hr_str)); %# Create x and y coordinates for the strings
title_str = varargin{6};
analysis_id = varargin{7};

figure('visible', 'off');
set(gcf, 'Position', [70, 10, 1200, 500]);
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
colormap bone;

subplot(1, 2, 1);
imagesc(mul_summary_mat);
textStrings = strtrim(cellstr(num2str(round_to(mul_summary_mat(:), 2), '%0.2f')));  %# Remove any space padding
%# Plot the strings
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(mul_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

title(sprintf('Multi. Log. regression, accuracy=%0.2f, error=%d\n%s', mul_accuracy, mul_total_errors, title_str), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Test', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Train', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:length(hr_str));
set(gca, 'XTickLabel', hr_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(hr_str));
set(gca, 'YTickLabel', hr_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

subplot(1, 2, 2);
imagesc(crf_summary_mat);
textStrings = strtrim(cellstr(num2str(round_to(crf_summary_mat(:), 2), '%0.2f')));  %# Remove any space padding
%# Plot the strings
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(crf_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

title(sprintf('Basic CRF, accuracy=%0.2f, error=%d\n%s', crf_accuracy, crf_total_errors, title_str), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Test', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Train', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:length(hr_str));
set(gca, 'XTickLabel', hr_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(hr_str));
set(gca, 'YTickLabel', hr_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

file_name = sprintf('%s/sparse_coding/%s/%s_summ_confmat', plot_dir, analysis_id, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = two_confusion_mats(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

assert(length(varargin) == 5);
mul_summary_mat = varargin{1};
crf_summary_mat = varargin{2};
ylim_l = min([min(mul_summary_mat(:)), min(crf_summary_mat(:))]);
ylim_u = max([max(mul_summary_mat(:)), max(crf_summary_mat(:))]);
title_str = varargin{3};
analysis_id = varargin{4};
plot_id = varargin{5};

[x, y] = meshgrid(1:length(label_str)); %# Create x and y coordinates for the strings
figure('visible', 'off'); set(gcf, 'Position', [70, 10, 1200, 500]);
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
colormap bone;

subplot(1, 2, 1);
imagesc(mul_summary_mat);
textStrings = strtrim(cellstr(num2str(mul_summary_mat(:), '%d')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(mul_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

title(sprintf('Multi. Log. regression, %s', title_str), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

subplot(1, 2, 2);
imagesc(crf_summary_mat);
textStrings = strtrim(cellstr(num2str(crf_summary_mat(:), '%d')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(crf_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

title(sprintf('Basic CRF, %s', title_str), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

file_name = sprintf('%s/sparse_coding/%s/%s_%s_two_confmat', plot_dir, analysis_id, analysis_id, plot_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = dictionary_elements(varargin)

global plot_dir;
global image_format;

nDictElements = varargin{1};
D = varargin{2};
analysis_id = varargin{3};

rs = 10; rc = 10;
figure('visible', 'off');
set(gcf, 'Position', get_project_settings('figure_size'));
% set(gcf, 'PaperPosition', [0 0 10 6]);
% set(gcf, 'PaperSize', [10 6]);
for d = 1:nDictElements
	subaxis(rs, rc, d, 'Spacing', 0.01, 'Padding', 0.01, 'Margin', 0.01);
	plot(D(:, d), 'LineWidth', 2); hold on;
	axis tight; grid on;
	set(gca, 'XTick', []);
	set(gca, 'YTick', []);
end
file_name = sprintf('%s/sparse_coding/misc_plots/%s_sparse_dict_elements', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_orig_recon(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

orig = varargin{1};
ecg_Y = varargin{2};
sparse_alpha = varargin{3};
D = varargin{4};
set_str = varargin{5};
window_size = size(D, 1);
nDictElements = size(D, 2);

for s = 1:length(ecg_Y)
	recon = D * sparse_alpha(1:nDictElements, :);
	peak_str = label_str{ecg_Y(s)};

	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));
	% set(gcf, 'PaperPosition', [0 0 6 6]);
	% set(gcf, 'PaperSize', [6 6]);

	y_lim = [min([orig(:, s); recon(:, s)])-1, max([orig(:, s); recon(:, s)])];

	plot(orig(:, s), 'r-', 'LineWidth', 2); hold on;
	plot(recon(:, s), 'b-', 'LineWidth', 2);
	hlegend = legend(sprintf('Original %s wave', peak_str), sprintf('Reconstructed %s wave', peak_str), 'Location', 'SouthWest',...
					'Orientation', 'Horizontal');
	set(hlegend, 'FontSize', le_fs, 'FontWeight', 'b', 'FontName', 'Times');

	grid on; xlim([1, window_size]);
	xlabel('Windowed peaks', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('Millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylim([y_lim]);
	
	file_name = sprintf('%s/sparse_coding/misc_plots/%s_sample%d', plot_dir, set_str, s);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = preprocess_ribbons(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

orig_ecg = varargin{1};
orig_norm_ecg = varargin{2};
orig_norm2_ecg = varargin{3};
varwin_ecg = varargin{4};
varwin_norm_ecg = varargin{5};
varwin_norm2_ecg = varargin{6};
ecg_test_Y = varargin{7};
hr = varargin{8};
analysis_id = varargin{9};

for l = 1:length(label_str)
	idx1 = ecg_test_Y == l;

	l_orig_ecg = orig_ecg(:, idx1)';
	x_final1 = 1:size(l_orig_ecg, 2);
	y_final1 = mean(l_orig_ecg, 1);
	interval1 = [y_final1 - std(l_orig_ecg, [], 1); y_final1 + std(l_orig_ecg, [], 1)];
	
	l_orig_norm_ecg = orig_norm_ecg(:, idx1)';
	x_final2 = 1:size(l_orig_norm_ecg, 2);
	y_final2 = mean(l_orig_norm_ecg, 1);
	interval2 = [y_final2 - std(l_orig_norm_ecg, [], 1); y_final2 + std(l_orig_norm_ecg, [], 1)];
	
	l_varwin_ecg = varwin_ecg(:, idx1)';
	x_final3 = 1:size(l_varwin_ecg, 2);
	y_final3 = mean(l_varwin_ecg, 1);
	interval3 = [y_final3 - std(l_varwin_ecg, [], 1); y_final3 + std(l_varwin_ecg, [], 1)];

	l_varwin_norm_ecg = varwin_norm_ecg(:, idx1)';
	x_final4 = 1:size(l_varwin_norm_ecg, 2);
	y_final4 = mean(l_varwin_norm_ecg, 1);
	interval4 = [y_final4 - std(l_varwin_norm_ecg, [], 1); y_final4 + std(l_varwin_norm_ecg, [], 1)];
	
	l_orig_norm2_ecg = orig_norm2_ecg(:, idx1)';
	x_final5 = 1:size(l_orig_norm2_ecg, 2);
	y_final5 = mean(l_orig_norm2_ecg, 1);
	interval5 = [y_final5 - std(l_orig_norm2_ecg, [], 1); y_final5 + std(l_orig_norm2_ecg, [], 1)];

	l_varwin_norm2_ecg = varwin_norm2_ecg(:, idx1)';
	x_final6 = 1:size(l_varwin_norm2_ecg, 2);
	y_final6 = mean(l_varwin_norm2_ecg, 1);
	interval6 = [y_final6 - std(l_varwin_norm2_ecg, [], 1); y_final6 + std(l_varwin_norm2_ecg, [], 1)];

	ymin = min([min(interval1(:)), min(interval3(:))]);
	ymax = max([max(interval1(:)), max(interval3(:))]);
	ymin2 = min([min(interval2(:)), min(interval4(:)), min(interval5(:)), min(interval6(:))]);
	ymax2 = max([max(interval2(:)), max(interval4(:)), max(interval5(:)), max(interval6(:))]);

	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));

	subplot(2, 3, 1); plot(x_final1, y_final1, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final1, interval1(1, :), interval1(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final1)]); ylim([ymin, ymax]);
	title(sprintf('Raw ECG'));

	subplot(2, 3, 2); plot(x_final2, y_final2, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final2, interval2(1, :), interval2(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final2)]); ylim([ymin2, ymax2]);
	title(sprintf('Normalized (Within) ECG'));

	subplot(2, 3, 3); plot(x_final5, y_final5, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final5, interval5(1, :), interval5(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final5)]); ylim([ymin2, ymax2]);
	title(sprintf('Normalized (Across) ECG'));

	subplot(2, 3, 4); plot(x_final3, y_final3, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final3, interval3(1, :), interval3(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final3)]); ylim([ymin, ymax]);
	title(sprintf('Variable Window ECG'));

	subplot(2, 3, 5); plot(x_final4, y_final4, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final4, interval4(1, :), interval4(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final4)]); ylim([ymin2, ymax2]);
	title(sprintf('Variable Window + Normalized (Within) ECG'));

	subplot(2, 3, 6); plot(x_final6, y_final6, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final6, interval6(1, :), interval6(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final6)]); ylim([ymin2, ymax2]);
	title(sprintf('Variable Window + Normalized (Across) ECG'));

	file_name = sprintf('%s/sparse_coding/misc_plots/%s_prepro_ribbons_hr%d_%speak', plot_dir, analysis_id, hr, label_str{l});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = gen_set_labels(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
label_clr = {'R', 'G', 'B', 'M', 'C', 'K'};

ecg_data = varargin{1};
time_cell = varargin{2};
crf_predlbl = varargin{3};
target_clusters = varargin{4};
target_idx = varargin{5};
analysis_id = varargin{6};
nSets = length(target_clusters);
assert(isequal(length(ecg_data), length(time_cell)));
assert(nSets == length(crf_predlbl));
assert(nSets == length(target_idx));

ecg_mat = [];
peak_labels = [];
idx_for_time = [];
idx_for_boundary = [];
for s = 1:nSets
	target_clusters_per_set = target_clusters{s};
	target_idx_per_set = target_idx{s};
	crf_predlbl_per_set = crf_predlbl{s};
	for l = 1:size(target_clusters_per_set, 2)
		% translates 1 to 38 (samples in the 1st cluster) into real indices as 42 to 771. Note when doing sparse coding we only
		% care about peaks at position 41, 83, ... 771.
		% Now to plot we care about everything in between as well hence the blanket index
		idx = target_idx_per_set(target_clusters_per_set(1, l)):target_idx_per_set(target_clusters_per_set(2, l));
		ecg_mat = [ecg_mat, ecg_data(1, idx)];
		idx_for_boundary = [idx_for_boundary, length(ecg_mat)];
		idx_for_time = [idx_for_time, idx];
		temp = zeros(1, length(idx));
		idx2 = target_idx_per_set(target_clusters_per_set(1, l):target_clusters_per_set(2, l));
		[junk, junk, plot_x_axis] = intersect(idx2, idx);	
		temp(plot_x_axis) = crf_predlbl_per_set(target_clusters_per_set(1, l):target_clusters_per_set(2, l));
		assert(all(temp(plot_x_axis) > 0) & all(temp(plot_x_axis) < 7));
		peak_labels = [peak_labels, temp];
	end
end
time_matrix = time_cell(1, idx_for_time);
assert(isequal(length(peak_labels), length(time_matrix)));
assert(isequal(length(ecg_mat), length(time_matrix)));

labelled_set = struct();
labelled_set.ecg_mat = ecg_mat;
labelled_set.time_matrix = time_matrix;
labelled_set.peak_labels = peak_labels;
labelled_set.idx_for_boundary = idx_for_boundary;
save(sprintf('%s/sparse_coding/%s/%s_labelled_set.mat', plot_dir, analysis_id(1:7), analysis_id), '-struct', 'labelled_set');

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = orig_recon_diff(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

assert(length(varargin) == 6);
ecg_test = varargin{1};
D = varargin{2}; 
test_alpha = varargin{3};
crf_predicted_label = varargin{4};
ecg_test_Y = varargin{5};
init_option = varargin{6};
nBins = 10;

for l = 1:length(label_str)
	idx = ecg_test_Y == l & ecg_test_Y == crf_predicted_label;
	corr_orig_peaks = ecg_test(:, idx);
	corr_recon_peaks = D * test_alpha(:, idx);

	idx = ecg_test_Y == l & ecg_test_Y ~= crf_predicted_label;
	incor_orig_peaks = ecg_test(:, idx);
	incor_recon_peaks = D * test_alpha(:, idx);

	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));
	for i = 1:size(ecg_test, 1)-1
		subplot(5, 10, i); scatter(corr_orig_peaks(i, :), corr_recon_peaks(i, :), 'bo');
		hold on; scatter(incor_orig_peaks(i, :), incor_recon_peaks(i, :), 'ro');
		axis tight; grid on;
		set(gca, 'XTick', []);
		set(gca, 'YTick', []);
		title(sprintf('%d', i));
		% legend('Correct', 'Incorrect');
		% xlabel('Original'); ylabel('Reconstruction');
	end

	file_name = sprintf('%s/sparse_coding/orig_recon_diff_%d_%speak', plot_dir, init_option, label_str{l});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

for l = 1:length(label_str)
	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));

	idx1 = ecg_test_Y == l & ecg_test_Y == crf_predicted_label;
	corr_recon_peaks = test_alpha(:, idx1)' * D';
	x_final1 = 1:size(corr_recon_peaks, 2);
	y_final1 = mean(corr_recon_peaks, 1);
	interval1 = [y_final1 - std(corr_recon_peaks, [], 1); y_final1 + std(corr_recon_peaks, [], 1)];
	
	corr_orig_peaks = ecg_test(:, idx1)';
	x_final2 = 1:size(corr_orig_peaks, 2);
	y_final2 = mean(corr_orig_peaks, 1);
	interval2 = [y_final2 - std(corr_orig_peaks, [], 1); y_final2 + std(corr_orig_peaks, [], 1)];
	
	idx2 = ecg_test_Y == l & ecg_test_Y ~= crf_predicted_label;
	incor_recon_peaks = test_alpha(:, idx2)' * D';
	x_final3 = 1:size(incor_recon_peaks, 2);
	y_final3 = mean(incor_recon_peaks, 1);
	interval3 = [y_final3 - std(incor_recon_peaks, [], 1); y_final3 + std(incor_recon_peaks, [], 1)];

	incor_orig_peaks = ecg_test(:, idx2)';
	x_final4 = 1:size(incor_orig_peaks, 2);
	y_final4 = mean(incor_orig_peaks, 1);
	interval4 = [y_final4 - std(incor_orig_peaks, [], 1); y_final4 + std(incor_orig_peaks, [], 1)];
	
	ymin = min([min(interval1(:)), min(interval2(:)), min(interval3(:)), min(interval4(:))]);
	ymax = max([max(interval1(:)), max(interval2(:)), max(interval3(:)), max(interval4(:))]);

	subplot(2, 2, 1); plot(x_final1, y_final1, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final1, interval1(1, :), interval1(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final1)]); ylim([ymin, ymax]);
	title(sprintf('Correct, reconstructed %s peaks(%d samples)', label_str{l}, sum(idx1)));

	subplot(2, 2, 2); plot(x_final2, y_final2, 'b-', 'LineWidth', 2); hold on; grid on;
	color = [89, 89, 89] ./ 255; transparency = 0.4;
	hhh = jbfill(x_final2, interval2(1, :), interval2(2, :), color, rand(1, 3), 0, transparency);
	hAnnotation = get(hhh, 'Annotation');
	hLegendEntry = get(hAnnotation', 'LegendInformation');
	set(hLegendEntry, 'IconDisplayStyle', 'off');
	xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final2)]); ylim([ymin, ymax]);
	title(sprintf('Correct, original %s peaks(%d samples)', label_str{l}, sum(idx1)));

	if sum(idx2) > 0
		subplot(2, 2, 3); plot(x_final3, y_final3, 'b-', 'LineWidth', 2); hold on; grid on;
		color = [89, 89, 89] ./ 255; transparency = 0.4;
		hhh = jbfill(x_final3, interval3(1, :), interval3(2, :), color, rand(1, 3), 0, transparency);
		hAnnotation = get(hhh, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final3)]); ylim([ymin, ymax]);
		title(sprintf('Incorrect, reconstructed %s peaks(%d samples)', label_str{l}, sum(idx2)));

		subplot(2, 2, 4); plot(x_final4, y_final4, 'b-', 'LineWidth', 2); hold on; grid on;
		color = [89, 89, 89] ./ 255; transparency = 0.4;
		hhh = jbfill(x_final4, interval4(1, :), interval4(2, :), color, rand(1, 3), 0, transparency);
		hAnnotation = get(hhh, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('windowed peaks'); ylabel('millivolts'); xlim([1, length(x_final4)]); ylim([ymin, ymax]);
		title(sprintf('Incorrect, original %s peaks(%d samples)', label_str{l}, sum(idx2)));
	end

	file_name = sprintf('%s/sparse_coding/ribbon_%d_%speak', plot_dir, init_option, label_str{l});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = incorrect_sample_time_series(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

assert(length(varargin) == 5);
incorrect_indices = varargin{1};
ecg_data = varargin{2}; 
labeled_peaks_idx = find(varargin{3});
estimated_hr = varargin{4};
hr_bins = varargin{5};

for i = 1:3
	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));

	subplot(2, 1, 1); plot(1:length(labeled_peaks_idx), ecg_data(labeled_peaks_idx), 'b-'); hold on;
	for j = 1:3
		[junk, idx, junk] = intersect(labeled_peaks_idx, incorrect_indices{i, j});
		text(idx, ecg_data(1, incorrect_indices{i, j}), sprintf('%d', j), 'FontSize', 15);
	end

	subplot(2, 1, 2); plot(1:length(labeled_peaks_idx), estimated_hr(labeled_peaks_idx), 'b-'); hold on;
	for j = 1:3
		[junk, idx, junk] = intersect(labeled_peaks_idx, incorrect_indices{i, j});
		text(idx, estimated_hr(1, incorrect_indices{i, j}), sprintf('%d', j), 'FontSize', 15);
	end
	plot(1:length(labeled_peaks_idx), repmat(hr_bins(1, 2), 1, length(labeled_peaks_idx)), 'g-');
	plot(1:length(labeled_peaks_idx), repmat(hr_bins(2, 2), 1, length(labeled_peaks_idx)), 'g-');

	file_name = sprintf('%s/sparse_coding/misc_plots/incorrect_samples%d', plot_dir, i);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = sparse_heat_maps(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

assert(length(varargin) == 6);
train_set = varargin{1};
test_set = varargin{2}; 
train_Y = varargin{3};
test_Y = varargin{4};
predicted_Y = varargin{5};
init_option = varargin{6};

for l = 1:length(label_str)
	clear train_heat_mat; clear test_cor_heat_mat; clear test_inc_heat_mat;

	figure('visible', 'off');
	set(gcf, 'Position', get_project_settings('figure_size'));

	idx = train_Y == l;
	train_heat_mat = train_set(idx, :)';

	idx = test_Y == l & test_Y == predicted_Y;
	test_cor_heat_mat = test_set(idx, :)';

	idx = test_Y == l & test_Y ~= predicted_Y;
	test_inc_heat_mat = test_set(idx, :)';

	% idx = find(sum([train_heat_mat, test_cor_heat_mat, test_inc_heat_mat], 2) ~= 0);
	idx = 1:size(test_inc_heat_mat, 1);
	dummy_mat = ones(length(idx), 1) .* 0.3;
	wgt_mat = [train_heat_mat(idx, :), dummy_mat, test_cor_heat_mat(idx, :), dummy_mat, test_inc_heat_mat(idx, :)];
	imagesc(wgt_mat);
	colormap gray; h = colorbar; set(h, 'ylim', [-0.15, 0.3]);
	ylabel('sparse codes'); xlabel(sprintf('Data samples[train(%d), test correct(%d), test incorrect(%d)]',...
				size(train_heat_mat, 2), size(test_cor_heat_mat, 2), size(test_inc_heat_mat, 2)));
	title(sprintf('%s peak', label_str{l}));

	%{
	subplot(1, 3, 1); imagesc(train_heat_mat(idx, :));
	ylabel('sparse codes'); xlabel('tr');
	title(sprintf('%s peak', label_str{l}));	
	h = colorbar;
	set(h, 'ylim', [-0.15, 0.25]);
	subplot(1, 3, 2); imagesc(test_cor_heat_mat(idx, :));
	xlabel('ts-c');
	set(gca, 'YTick', []);
	h = colorbar;
	set(h, 'ylim', [-0.15, 0.25]);
	subplot(1, 3, 3); imagesc(test_inc_heat_mat(idx, :));
	xlabel('ts-i');
	set(gca, 'YTick', []);
	h = colorbar;
	set(h, 'ylim', [-0.15, 0.25]);
	%}

	file_name = sprintf('%s/sparse_coding/sparse_heatmaps%d_%speak', plot_dir, init_option, label_str{l});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = function_of_lambda(varargin)

global plot_dir;
global image_format;

assert(length(varargin) == 4);
mul_acc = varargin{1};
crf_acc = varargin{2}; 
mean_dict = varargin{3};
lambda = varargin{4};

% figure('visible', 'off');
figure();
set(gcf, 'Position', get_project_settings('figure_size'));
subplot(2, 1, 1); plot(1:length(lambda), mul_acc, 'ro-'); hold on;
plot(1:length(lambda), crf_acc, 'go-');
set(gca, 'XTick', 1:length(lambda));
set(gca, 'XTickLabel', lambda);
legend('MUL', 'CRF');
xlabel('sparse coding Lambda');
ylabel('Error count');

subplot(2, 1, 2); plot(1:length(lambda), mean_dict, 'ko-');
set(gca, 'XTick', 1:length(lambda));
set(gca, 'XTickLabel', lambda);
xlabel('sparse coding Lambda');
ylabel('No. Dictionary elements');

file_name = sprintf('%s/sparse_coding/function_of_lambda', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

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
function[] = train_test_linear(varargin)

global plot_dir;
global image_format;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

target_samples = varargin{1};
ecg_sparse_feats = varargin{2};
peak_labels = varargin{3};
alpha = varargin{4};
D = varargin{5};
actual_idx = varargin{6};
if length(varargin) == 8
	predicted_label = varargin{8};
end

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

for tr = 1:length(target_samples)
	top_dict_elements_plot = 10;

	title_str = sprintf('%s wave', label_str{peak_labels(actual_idx(target_samples(tr)))});
	if exist('predicted_label')
		title_str = sprintf('grnd: %s, pred: %s', label_str{peak_labels(actual_idx(target_samples(tr)))},...
							  label_str{predicted_label(target_samples(tr))});
	end

	target_dict_elements = find(alpha(:, target_samples(tr)));
	[junk, sorted_idx] = sort(alpha(target_dict_elements, target_samples(tr)), 'descend');
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
		[junk, junk, val] = find(alpha(target_dict_elements(d), target_samples(tr)));
		title(sprintf('alpha=%0.4f', val));
	end

	subplot(4, 5, [11, 12, 16, 17]);
	plot(ecg_sparse_feats(:, target_samples(tr)), 'r-', 'LineWidth', 2); hold on;
	plot(D(:, target_dict_elements) * alpha(target_dict_elements, target_samples(tr)), 'g-');
	y_lim = get(gca, 'ylim');
	title(sprintf('Top 10 feats; %s', title_str));
	legend('Original', 'Sparse', 'Location', 'NorthWest');
	grid on;

	subplot(4, 5, [14, 15, 19, 20]);
	plot(ecg_sparse_feats(:, target_samples(tr)), 'r-', 'LineWidth', 2); hold on;
	plot(D * alpha(:, target_samples(tr)), 'g-');
	ylim([y_lim]);
	title(sprintf('All feats (%d); %s', length(find(alpha(:, target_samples(tr)))), title_str));
	grid on;

	file_name = sprintf('%s/sparse_coding/misc_plots/%s_lab%d', plot_dir, varargin{7}, target_samples(tr));
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

load(fullfile(results_dir, 'labeled_peaks/assigned_hr_bl_subtract_sgram_071313.mat'));
sgram_new_range = assigned_hr;

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(sgram_based_hr, 'b-'); hold on;
plot(sgram_big_hr, 'r-');
plot(sgram_new_range, 'g-');
plot(behav_hr(peak_idx), 'ko', 'MarkerFaceColor', 'k');

xlabel('peaks ONLY'); ylabel('heart rate');
legend('Sgram 0.6 min', 'Sgram 2 min', 'Sgram 70-140', 'behav');
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

%{
figure('visible', 'off');
set(gcf, 'Position', get_project_settings('figure_size'));
% translates 1 to 38 (samples in the 1st cluster) into real indices as 42 to 771. Note when doing sparse coding we only
% care about peaks at position 41, 83, ... 771. Now to plot we care about everything in between as well hence the blanket index
idx = target_idx(target_clusters(1, l)):target_idx(target_clusters(2, l));
plot(ecg_data(1, idx), 'b-'); hold on;
% idx2 is only the peak locations like 41, 83, ... 771
idx2 = target_idx(target_clusters(1, l):target_clusters(2, l));
cluster_ecg_data = ecg_data(1, idx2);

% Intersecting these two will tell me where the clusters are sitting in the blanket vector
[junk, junk, plot_x_axis] = intersect(idx2, idx);

for lbl = 1:length(label_str)
	% I use the intersect info to plot the six different types of peaks
	idx3 = crf_predlbl(target_clusters(1, l):target_clusters(2, l)) == lbl;
	text(plot_x_axis(idx3), cluster_ecg_data(1, idx3), label_str{lbl}, 'FontWeight', 'Bold', 'color', label_clr{lbl});
end
file_name = sprintf('%s/sparse_coding/%s/learn%d_cluster', plot_dir, analysis_id, l);
savesamesize(gcf, 'file', file_name, 'format', image_format);
%}

%}

%{
keyboard		
for r = 1:size(result, dimm)
switch dimm
case 1
	temp_idx = find(result(r, :));
	if length(temp_idx) > 1
		result(r, temp_idx(2:end)) = 0;
	end
case 2
	temp_idx = find(result(:, r));
	if length(temp_idx) > 1
		result(temp_idx(2:end), r) = 0;
	end
end
end
keyboard		
%}

