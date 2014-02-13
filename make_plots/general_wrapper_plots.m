function[] = general_wrapper_plots(which_plot, analysis_id)

close all;

global plot_dir
plot_dir = get_project_settings('plots');
global image_format
image_format = get_project_settings('image_format');
% image_format = 'pdf';

switch which_plot
case 1, multiple_matching_windows(analysis_id);;
case 2, multiple_runs_T_preservation(analysis_id);
case 3, multiple_runs_R_partition(analysis_id);
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
title(sprintf('P20-040, PUwave perf. Matching windows runs, time 50-50'));
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
title(sprintf('P20-040, Multiple runs, time 50-50'));
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
title(sprintf('P20-040, Multiple runs, random 50-50'));
set(gca, 'XTick', 1:size(results_mean, 1));
set(gca, 'XTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
legend({'Mul', 'PUWave', 'CRF'}, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
file_name = sprintf('%s/sparse_coding/%s/multiple_R_runs', plot_dir, analysis_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

