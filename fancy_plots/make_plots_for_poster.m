function[] = make_plots_for_poster()

close all;

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
rr_thresholds = 0.05;
subject_id = 'P20_040';
subject_sensor = 'Sensor_1';
subject_timestamp = '2012_06_27-09_21_36';
time_window = 30;
event = 'cocn';
tr_percent = 60;
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
y = ecg_mat(1.922e+6:1.922e+6+8749, 7) * 0.001220703125;
x = 1:length(y);
[rr, rs] = rrextract(y, raw_ecg_mat_time_res, rr_thresholds);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
peak_data = load(fullfile(result_dir, subject_id, sprintf('%s_pqrst_peaks_slide%d.mat', event, time_window)));
window_data = load(fullfile(result_dir, subject_id, sprintf('%s_slide%d_win.mat', event, time_window)));
window_data = window_data.pqrst_mat;
nSamples_per_window_col = size(window_data, 2)-2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classifier_results = load(fullfile(result_dir, subject_id, sprintf('classifier_results_tr%d.mat', tr_percent)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

start_sli_win = 1:250:8751;
end_sli_win = start_sli_win(end-4:end)-1;
start_sli_win = start_sli_win(1:5);
y_vals = 2.40:-0.01:2.36;

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
h1 = plot(x, y, 'b-', 'Linewidth', 2); hold on;
h2 = plot(rr, y(rr), 'r*', 'MarkerSize', 10);
xlabel('sample ECG trace (milliseconds)', 'fontweight', 'bold', 'fontsize', 10);
ylabel('millivolts', 'fontweight', 'bold', 'fontsize', 10);
title('ECG trace + RR peak detection + sliding window', 'fontweight', 'bold', 'fontsize', 12);
xlim([-10, length(y)]);
for yy = 1:length(y_vals)
	x_vals = start_sli_win(yy):1:end_sli_win(yy);
	h3 = plot(x_vals, repmat(y_vals(yy), 1, length(x_vals)), 'k-', 'LineWidth', 2);
	little_y_vals = y_vals(yy):0.001:y_vals(yy)+0.005;
	plot(repmat(x_vals(1), 1, length(little_y_vals)), little_y_vals, 'k-', 'LineWidth', 2);
	plot(repmat(x_vals(end), 1, length(little_y_vals)), little_y_vals, 'k-', 'LineWidth', 2);
end
legend([h1, h2, h3], 'Raw ECG', 'RR peaks', 'Sliding windows');
file_name = sprintf('/home/anataraj/NIH-craving/poster_plots/raw_ecg');
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

peak_exists = find(peak_data.p_point(:, 1) > 0);
samples_exist = find(window_data(:, nSamples_per_window_col) > 0);
target_idx = intersect(peak_exists, samples_exist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
title(sprintf('All windows + peak detection'), 'fontweight', 'bold', 'fontsize', 12);
hold on; grid on;
set(gca, 'box', 'on');
xlim([0, nInterpolatedFeatures]); ylim([-4, 5.5]);
ylabel('Standardized millivolts', 'fontweight', 'bold', 'fontsize', 15);
xlabel('Interpolated ECG features', 'fontweight', 'bold', 'fontsize', 15);
interleave_samples = 1:151:length(target_idx);
colors = gray(length(interleave_samples)+25);
for s = 1:length(interleave_samples)
	tt = target_idx(interleave_samples(s));
	plot(window_data(tt, ecg_col), 'color', colors(s, :), 'LineWidth', 2);
	hold on;
	h1 = plot(peak_data.p_point(tt, 1), peak_data.p_point(tt, 2), 'kd', 'MarkerSize', 10);
	h2 = plot(peak_data.q_point(tt, 1), peak_data.q_point(tt, 2), 'ko', 'MarkerSize', 10);
	h3 = plot(peak_data.r_point(tt, 1), peak_data.r_point(tt, 2), 'ks', 'MarkerSize', 10);
	h4 = plot(peak_data.s_point(tt, 1), peak_data.s_point(tt, 2), 'k^', 'MarkerSize', 10);
	h5 = plot(peak_data.t_point(tt, 1), peak_data.t_point(tt, 2), 'k*', 'MarkerSize', 10);
end
legend([h1, h2, h3, h4, h5], 'P peak', 'Q trough', 'R peak', 'S trough', 'T peak');

file_name = sprintf('/home/anataraj/Dropbox/NIH plots/AMIA_poster/peaks');
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
print(gcf, '-dpdf', '-painters', file_name);

keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colors = jet(size(target_idx, 1));
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
title(sprintf('All windows + peak detection'), 'fontweight', 'bold', 'fontsize', 12);
hold on; grid on;
xlim([0, nInterpolatedFeatures]); ylim([-4, 5.5]);
ylabel('standardized millivolts', 'fontweight', 'bold', 'fontsize', 10);
xlabel('Interpolated ECG features', 'fontweight', 'bold', 'fontsize', 10);
for s = 1:size(target_idx, 1)
	plot(window_data(target_idx(s), ecg_col), 'color', colors(s, :));
	hold on;
end
file_name = sprintf('/home/anataraj/NIH-craving/poster_plots/window_data');
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(); set(gcf, 'Position', get_project_settings('figure_size'));

nAnalysis = length(classifier_results.mean_over_runs);
legend_str = {};
for a = 1:nAnalysis
	nFeatures = length(classifier_results.mean_over_runs{1, a});
	class_label = classifier_results.class_label{1, a};
	legend_str{a} = sprintf('%s vs %s', class_label{1}, class_label{2});
	feature_str = classifier_results.feature_str{1, a};
end

bar([classifier_results.auc_over_runs{:}]);
legend(legend_str, 'Location', 'South', 'Orientation', 'Horizontal');
xlabel('Features', 'fontweight', 'bold', 'fontsize', 10);
ylabel('AUROC', 'fontweight', 'bold', 'fontsize', 10);
set(gca, 'XTick', 1:nFeatures);
set(gca, 'XTickLabel', feature_str);
xlim([0.5, nFeatures+0.5]); grid on;
title(sprintf('Logistic reg., Area under ROC'), 'fontweight', 'bold', 'fontsize', 12);
file_name = sprintf('/home/anataraj/NIH-craving/poster_plots/auroc');
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

keyboard

