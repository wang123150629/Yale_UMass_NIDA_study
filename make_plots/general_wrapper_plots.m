function[] = general_wrapper_plots(which_plot, analysis_id, varargin)

close all;

global plot_dir
plot_dir = get_project_settings('plots');
global image_format
image_format = get_project_settings('image_format');
paper_quality = false;
if length(varargin) == 1
	paper_quality = varargin{1};
end

switch which_plot
case 1, multiple_matching_windows(analysis_id);
case 2, multiple_runs_T_preservation(analysis_id);
case 3, multiple_runs_R_partition(analysis_id);
case 4, cross_validation(analysis_id, paper_quality);
case 5, fetch_results(analysis_id);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = fetch_results(analysis_id)

global plot_dir

load(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id));
compute_prec_recall(ground_truth, crf);
compute_prec_recall(matching_confusion_mat);
compute_prec_recall(ground_truth, mul_nom);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = compute_prec_recall(varargin)

if length(varargin) == 2
	vector_a = varargin{1};
	vector_b = varargin{2};
	confusion_mat = confusionmat(vector_a(vector_a > 0), vector_b(vector_b > 0));
else
	confusion_mat = varargin{1};
end
% dispf('Label counts');
% sum(confusion_mat, 2)'
% dispf('Accuracies');
% bsxfun(@rdivide, confusion_mat, sum(confusion_mat, 2))

confusion_mat

tp = diag(confusion_mat)';
fp = sum(confusion_mat, 1) - tp;
fn = sum(confusion_mat, 2)' - tp;

stats = [tp; fp; fn; tp ./ (tp + fp); tp ./ (tp + fn)];
% dispf('tp fp fn pres recal');
% dispf('\\textbf{} & \\textbf{P} & %d & %d & %d & %0.4f & %0.4f \\\\ \\hline\n', stats);

stats = stats(:, 1:end-1);
another_stats = [mean(stats, 2)'; std(stats, [], 2)'];

% dispf('\\textbf{} & \\textbf{} & %0.2f$\\pm%0.2f$ & %0.2f$\\pm%0.2f$ & %0.2f$\\pm%0.2f$ & %0.4f$\\pm%0.2f$ & %0.4f$\\pm%0.2f$ \\\\ \\hline\n', another_stats);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = cross_validation(analysis_id, paper_quality)

global plot_dir;
global image_format;

load(fullfile(plot_dir, 'sparse_coding', analysis_id, sprintf('%s_results.mat', analysis_id)));

nPipelines = 1:numel(crf_validate_errors{1});

min_folds = reshape([crf_validate_errors{:}], length(nPipelines), k_fold)';
[junk, min_folds] = min(min_folds, [], 2);
count_pipelines = histc(min_folds, nPipelines);
dispf('CRF, pipeline=%d, count=%d\n', [nPipelines(count_pipelines > 0); count_pipelines(count_pipelines > 0)']);

min_folds = reshape([mul_validate_errors{:}], length(nPipelines), k_fold)';
[junk, min_folds] = min(min_folds, [], 2);
count_pipelines = histc(min_folds, nPipelines);
dispf('MUL, pipeline=%d, count=%d\n', [nPipelines(count_pipelines > 0); count_pipelines(count_pipelines > 0)']);

mul_to_plot = NaN(k_fold, 6);
matching_to_plot = NaN(k_fold, 6);
crf_to_plot = NaN(k_fold, 6);
for r = 1:k_fold
	mul_to_plot(r, :) = diag(bsxfun(@rdivide, mul_confusion_mat{r}, sum(mul_confusion_mat{r}, 2)));
	matching_to_plot(r, :) = diag(bsxfun(@rdivide, matching_confusion_mat{r}, sum(matching_confusion_mat{r}, 2)));
	crf_to_plot(r, :) = diag(bsxfun(@rdivide, crf_confusion_mat{r}, sum(crf_confusion_mat{r}, 2)));
end
results_mean = [mean(mul_to_plot); mean(matching_to_plot); mean(crf_to_plot)]';
results_std = [std(mul_to_plot, [], 1); std(matching_to_plot, [], 1); std(crf_to_plot, [], 1)]';

if paper_quality
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

	results_mean = results_mean(1:end-1, :);
	results_std = results_std(1:end-1, :);
	figure(); set(gcf, 'Position', [10, 10, 1200, 600]);
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	h = bar(results_mean);
	set(h, 'BarWidth', 1); % The bars will now touch each other
	hold on; grid on;
	numgroups = size(results_mean, 1);
	numbars = size(results_mean, 2);
	groupwidth = min(0.8, numbars/(numbars+1.5));
	for i = 1:numbars
		% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
		x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
		errorbar(x, results_mean(:,i), results_std(:,i), 'k', 'linestyle', 'none', 'LineWidth', 1);
	end
	xlabel('Peaks', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('Accuracy', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylim([0.7, 1+0.03]);
	xlim([0, 6]);
	title(sprintf('%s', get_project_settings('strrep_subj_id', subject_id)),...
						'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	set(gca, 'XTick', 1:size(results_mean, 1), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T'}, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	hlegend = legend({'Mul', 'PUWave', 'CRF'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
	set(hlegend, 'FontSize', le_fs, 'FontWeight', 'b', 'FontName', 'Times');
	file_name = sprintf('%s/sparse_coding/%s/cross_val_runs', plot_dir, analysis_id);
	saveas(gcf, file_name, 'pdf');
else
	figure(); set(gcf, 'Position', get_project_settings('figure_size'));
	h = bar(results_mean);
	set(h, 'BarWidth', 1); % The bars will now touch each other
	hold on; grid on;
	numgroups = size(results_mean, 1);
	numbars = size(results_mean, 2);
	groupwidth = min(0.8, numbars/(numbars+1.5));
	for i = 1:numbars
		% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
		x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
		errorbar(x, results_mean(:,i), results_std(:,i), 'k', 'linestyle', 'none', 'LineWidth', 2);
	end
	xlabel('Peaks');
	ylabel('Accuracy');
	ylim([0.7, 1+0.03]);
	xlim([0, 7]);
	title(sprintf('%s, cross validation, train-validate-test', get_project_settings('strrep_subj_id', subject_id)));
	set(gca, 'XTick', 1:size(results_mean, 1));
	set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
	legend({'Mul', 'PUWave', 'CRF'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
	file_name = sprintf('%s/sparse_coding/%s/cross_val_runs', plot_dir, analysis_id);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = multiple_matching_windows(analysis_id)

global plot_dir;
global image_format;

load(fullfile(plot_dir, 'sparse_coding', analysis_id, sprintf('%s_results.mat', analysis_id)));

mul_to_plot = NaN(length(matching_pm), 6);
matching_to_plot = NaN(length(matching_pm), 6);
crf_to_plot = NaN(length(matching_pm), 6);
for r = 1:length(matching_pm)
	mul_to_plot(r, :) = diag(bsxfun(@rdivide, mul_confusion_mat{r}, sum(mul_confusion_mat{r}, 2)));
	matching_to_plot(r, :) = diag(bsxfun(@rdivide, matching_confusion_mat{r}, sum(matching_confusion_mat{r}, 2)));
	crf_to_plot(r, :) = diag(bsxfun(@rdivide, crf_confusion_mat{r}, sum(crf_confusion_mat{r}, 2)));
end
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(matching_to_plot, 'o-', 'LineWidth', 2);
grid on;
xlabel('Matching window sizes');
ylabel('Accuracy');
ylim([min(matching_to_plot(:))-0.01, max(matching_to_plot(:))+0.01]);
xlim([1, length(matching_pm)]);
title(sprintf('%s, varying matching windows, T:train-validate-test', get_project_settings('strrep_subj_id', subject_id)));
set(gca, 'XTick', 1:length(matching_pm));
temp = strcat(setstr(177), strread(num2str(matching_pm),'%s'));
set(gca, 'XTickLabel', temp);
legend({'P', 'Q', 'R', 'S', 'T', 'U'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/%s/matching_wins', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = multiple_runs_T_preservation(analysis_id)

global plot_dir;
global image_format;

load(fullfile(plot_dir, 'sparse_coding', analysis_id, sprintf('%s_results.mat', analysis_id)));

mul_to_plot = NaN(length(runs), 6);
matching_to_plot = NaN(length(runs), 6);
crf_to_plot = NaN(length(runs), 6);
for r = runs
	mul_to_plot(r, :) = diag(bsxfun(@rdivide, mul_confusion_mat{r}, sum(mul_confusion_mat{r}, 2)));
	matching_to_plot(r, :) = diag(bsxfun(@rdivide, matching_confusion_mat{r}, sum(matching_confusion_mat{r}, 2)));
	crf_to_plot(r, :) = diag(bsxfun(@rdivide, crf_confusion_mat{r}, sum(crf_confusion_mat{r}, 2)));
end
results_mean = [mean(mul_to_plot); mean(matching_to_plot); mean(crf_to_plot)]';
results_std = [std(mul_to_plot, [], 1); std(matching_to_plot, [], 1); std(crf_to_plot, [], 1)]';

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
h = bar(results_mean);
set(h, 'BarWidth', 1); % The bars will now touch each other
hold on; grid on;
numgroups = size(results_mean, 1);
numbars = size(results_mean, 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
	% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
	x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
	errorbar(x, results_mean(:,i), results_std(:,i), 'k', 'linestyle', 'none', 'LineWidth', 2);
end
xlabel('Peaks');
ylabel('Accuracy');
ylim([0, 1.01]);
xlim([0, 7]);
title(sprintf('%s, Multiple runs, T:train-validate-test', get_project_settings('strrep_subj_id', subject_id)));
set(gca, 'XTick', 1:size(results_mean, 1));
set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
legend({'Mul', 'PUWave', 'CRF'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/%s/multiple_T_runs', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = multiple_runs_R_partition(analysis_id)

global plot_dir;
global image_format;

load(fullfile(plot_dir, 'sparse_coding', analysis_id, sprintf('%s_results.mat', analysis_id)));

mul_to_plot = NaN(length(runs), 6);
matching_to_plot = NaN(length(runs), 6);
crf_to_plot = NaN(length(runs), 6);
for r = runs
	mul_to_plot(r, :) = diag(bsxfun(@rdivide, mul_confusion_mat{r}, sum(mul_confusion_mat{r}, 2)));
	matching_to_plot(r, :) = diag(bsxfun(@rdivide, matching_confusion_mat{r}, sum(matching_confusion_mat{r}, 2)));
	crf_to_plot(r, :) = diag(bsxfun(@rdivide, crf_confusion_mat{r}, sum(crf_confusion_mat{r}, 2)));
end
results_mean = [mean(mul_to_plot); mean(matching_to_plot); mean(crf_to_plot)]';
results_std = [std(mul_to_plot, [], 1); std(matching_to_plot, [], 1); std(crf_to_plot, [], 1)]';

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
h = bar(results_mean);
set(h, 'BarWidth', 1); % The bars will now touch each other
hold on; grid on;
numgroups = size(results_mean, 1);
numbars = size(results_mean, 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
	% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
	x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
	errorbar(x, results_mean(:,i), results_std(:,i), 'k', 'linestyle', 'none', 'LineWidth', 2);
end
xlabel('Peaks');
ylabel('Accuracy');
ylim([0, 1+0.03]);
xlim([0, 7]);
title(sprintf('%s, Multiple runs, R:train-validate-test', get_project_settings('strrep_subj_id', subject_id)));
set(gca, 'XTick', 1:size(results_mean, 1));
set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
legend({'Mul', 'PUWave', 'CRF'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/%s/multiple_R_runs', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

