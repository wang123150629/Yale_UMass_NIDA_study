function[mat_return] = build_confusn_matrices(record_no, analysis_id, varargin)

close all;
plot_dir = get_project_settings('plots');

target_rec = 'P20_040';
global label_str
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};

nAnnotations = numel(label_str)-1;
naive_pm = 2;
if length(varargin) >= 1
	matching_pm = varargin{1};
end

load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s.mat', record_no)));
ecg_mat_puwave = ecg_mat;
clear ecg_mat;

peak_labels_puwave = ones(size(ecg_mat_puwave)) .* 6;
% if all(peak_labels_puwave(1, annt.P(~isnan(annt.P))) > 5)
	peak_labels_puwave(1, annt.P(~isnan(annt.P))) = 1;
% end
% if all(peak_labels_puwave(1, annt.Q(~isnan(annt.Q))) > 5)
	peak_labels_puwave(1, annt.Q(~isnan(annt.Q))) = 2;
% end
% if all(peak_labels_puwave(1, annt.R(~isnan(annt.R))) > 5)
	peak_labels_puwave(1, annt.R(~isnan(annt.R))) = 3;
% end
% if all(peak_labels_puwave(1, annt.S(~isnan(annt.S))) > 5)
	% nine labels 7 - Q's and 2 - P's
	peak_labels_puwave(1, annt.S(~isnan(annt.S))) = 4;
% end
% if all(peak_labels_puwave(1, annt.T(~isnan(annt.T))) > 5)
	peak_labels_puwave(1, annt.T(~isnan(annt.T))) = 5;
% end
assert(sum(isnan(peak_labels_puwave)) == 0);
assert(length(unique(peak_labels_puwave)) == 6);

if strcmp(record_no(1:length(target_rec)), target_rec) | strcmp(record_no(1:length(target_rec)), target_rec)
	misc_mat = load(sprintf(sprintf('misc_mats/%s_info.mat', analysis_id)));
	magic_idx = [1.29e+5:7.138e+5, 7.806e+5:3.4e+6, 3.515e+6:length(misc_mat.ts_grnd_lbl)];
	title_str = {sprintf('Mul Log. Reg.'), sprintf('Matching, %s%d', setstr(177), matching_pm),...
		     sprintf('Basic CRF\n%s', misc_mat.title_str)};
	misc_mat.mul_confusion_mat
	% sum(misc_mat.mul_confusion_mat, 2)'
	mlr_summary_mat = bsxfun(@rdivide, misc_mat.mul_confusion_mat, sum(misc_mat.mul_confusion_mat, 2));
	
	crf_pred_lbl = misc_mat.peak_labels(1, magic_idx);
	assert(isequal(size(crf_pred_lbl), size(ecg_mat_puwave)));
	assert(sum(isnan(crf_pred_lbl)) == 0);

	ecg_test_Y = misc_mat.ts_grnd_lbl(1, magic_idx);
	target_idx = find(misc_mat.ts_grnd_lbl(1, magic_idx));

	matching_summary_mat = matching_driver(target_idx, ecg_test_Y, annt, matching_pm, crf_pred_lbl)
	% sum(matching_summary_mat, 2)'
	matching_summary_mat = bsxfun(@rdivide, matching_summary_mat, sum(matching_summary_mat, 2));

	crf_summary_mat = confusionmat(ecg_test_Y(target_idx), crf_pred_lbl(target_idx))
	% sum(crf_summary_mat, 2)'
	crf_summary_mat = bsxfun(@rdivide, crf_summary_mat, sum(crf_summary_mat, 2));

	print_confusion_mats(title_str, mlr_summary_mat, matching_summary_mat, crf_summary_mat);
end
file_name = sprintf('scripts/ecgpuwave_misc/%s', analysis_id);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

mat_return = [];
if length(varargin) == 2
	switch varargin{2}
	case 1
		mat_return = matching_summary_mat;
	case 2
		mat_return = crf_summary_mat;
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = print_confusion_mats(title_str, varargin)

nMatrices = length(varargin);

global label_str;
[x, y] = meshgrid(1:length(label_str)); %# Create x and y coordinates for the strings

font_size = get_project_settings('font_size');
tl_fs = font_size(6);

total_entries = length(varargin)*size(varargin{1}, 1)*size(varargin{1}, 2);
ylim_l = min(reshape(cell2mat(varargin), 1, total_entries));
ylim_u = max(reshape(cell2mat(varargin), 1, total_entries));

figure('visible', 'on');
if length(varargin) > 2
	set(gcf, 'Position', [70, 900, 1300, 400]);
else
	set(gcf, 'Position', [70, 900, 1200, 500]);
end
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
colormap bone;

for i = 1:nMatrices
	subplot(1, nMatrices, i);
	fancy_write_out_mat(varargin{i}, x, y, ylim_l, ylim_u)
	title(title_str{i}, 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = fancy_write_out_mat(A, x, y, ylim_l, ylim_u)

global label_str;
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
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

%{
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
for i = 1:5
	a = find(peak_labels_puwave == i);
	b = find(crf_pred_lbl == i);
	ccount = 0;
	ccount = ccount + length(intersect(a, b));
	for j = 1:5
		ccount = ccount + length(intersect(a, b+j));
		ccount = ccount + length(intersect(a, b-j));
	end
	fprintf('%s wave count = %d\n', label_str{i}, ccount);
end

subplot(1, 2, 1);
imagesc(puw_summary_mat);
textStrings = strtrim(cellstr(num2str(puw_summary_mat(:), '%0.2f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(puw_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

title(sprintf('PUWave, %s', pm_win{1}), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

subplot(1, 2, 2);
imagesc(crf_summary_mat);
textStrings = strtrim(cellstr(num2str(crf_summary_mat(:), '%0.2f')));  %# Remove any space padding
hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
midValue = mean(get(gca, 'CLim'));  %# Get the middle value of the color range
% Choose white or black for the text color of the strings so they can be easily seen over the background color
textColors = repmat(crf_summary_mat(:) < midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));  %# Change the text colors
h = colorbar;
set(h, 'ylim', [ylim_l, ylim_u]);

set(gca, 'XTick', 1:length(label_str));
set(gca, 'XTickLabel', label_str, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'YTick', 1:length(label_str));
set(gca, 'YTickLabel', label_str, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Predicted', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Ground', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

%}

%{
S.pk_pushh = uicontrol('Style', 'pushbutton', 'String', 'LABEL PEAKS',...
		  'Position', [20 y_location-90 100 20],...
		  'Callback', {@monitor_clicks, S});

S.un_pushh = uicontrol('Style', 'pushbutton', 'String', 'UNDO',...
		  'Position', [20 y_location-120 100 20],...
		  'Callback', {@undo_peaks, S});

S.sv_pushh = uicontrol('Style', 'pushbutton', 'String', 'SAVE LABELS',...
		  'Position', [20 y_location-150 100 20],...
		  'Callback', @save_mats);
%}

%{
assert(min(diff(target_idx)) > naive_pm);
windowed_labels = ones(size(target_idx)) .* 6;
for i = 1:nAnnotations
	% sum(peak_labels_puwave == i)
	grnd_trth_lbl_locations = find(ecg_test_Y(target_idx) == i);
	toolbx_lbl_locations = find(peak_labels_puwave(target_idx) == i);
	desired_idx = intersect(grnd_trth_lbl_locations, toolbx_lbl_locations);
	assert(all(windowed_labels(desired_idx) > 5));
	windowed_labels(desired_idx) = i;
	% sum(windowed_labels == i)
	if naive_pm > 0
		for p = 1:naive_pm
			toolbx_lbl_locations = find(peak_labels_puwave(target_idx - p) == i);
			desired_idx = intersect(grnd_trth_lbl_locations, toolbx_lbl_locations);
			assert(all(windowed_labels(desired_idx) > 5));
			windowed_labels(desired_idx) = i;

			toolbx_lbl_locations = find(peak_labels_puwave(target_idx + p) == i);
			desired_idx = intersect(grnd_trth_lbl_locations, toolbx_lbl_locations);
			assert(all(windowed_labels(desired_idx) > 5));
			windowed_labels(desired_idx) = i;
			% sum(windowed_labels == i)
		end
	end
end
puw_summary_mat = confusionmat(ecg_test_Y(target_idx), windowed_labels);
puw_summary_mat = bsxfun(@rdivide, puw_summary_mat, sum(puw_summary_mat, 2));
%}
