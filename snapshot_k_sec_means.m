function[] = snapshot_k_sec_means(subject_id, time_window, event)

% snapshot_k_sec_means('P20_040', 30, 'cocn')

close all;

result_dir = get_project_settings('results');

peak_data = load(fullfile(result_dir, subject_id, sprintf('%s_pqrst_peaks_slide%d.mat', event, time_window)));
window_data = load(fullfile(result_dir, subject_id, sprintf('%s_slide%d_win.mat', event, time_window)));
window_data = window_data.pqrst_mat;

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
nSamples_per_window_col = size(window_data, 2)-2;

peak_exists = find(peak_data.p_point(:, 1) > 0);
samples_exist = find(window_data(:, nSamples_per_window_col) > 0);
target_idx = intersect(peak_exists, samples_exist);

start_idx = [(1:100:length(target_idx))', ([100:100:length(target_idx), length(target_idx)])'];

colors = jet(size(start_idx, 1));
figure(); set(gcf, 'Position', get_project_settings('figure_size'));
title(sprintf('%s, all sessions', get_project_settings('strrep_subj_id', subject_id))); hold on;
xlim([0, nInterpolatedFeatures]); ylim([-4, 5.5]);
ylabel('std. millivolts'); xlabel('Interpolated ECG features');
grid on;
for s = 35:size(start_idx, 1)
	avgd_data = mean(window_data(start_idx(s, 1):start_idx(s, 2), ecg_col));
	plot(avgd_data, 'color', colors(s, :));
	%{
	hold on;
	plot(peak_data.p_point(target_idx(s), 1), peak_data.p_point(target_idx(s), 2), 'r*', 'MarkerSize', 10);
	plot(peak_data.q_point(target_idx(s), 1), peak_data.q_point(target_idx(s), 2), 'g*', 'MarkerSize', 10);
	plot(peak_data.r_point(target_idx(s), 1), peak_data.r_point(target_idx(s), 2), 'b*', 'MarkerSize', 10);
	plot(peak_data.s_point(target_idx(s), 1), peak_data.s_point(target_idx(s), 2), 'k*', 'MarkerSize', 10);
	plot(peak_data.t_point(target_idx(s), 1), peak_data.t_point(target_idx(s), 2), 'm*', 'MarkerSize', 10);
	pause(0.25);
	%}
	file_name = sprintf('/home/anataraj/Dropbox/temp_hold/plot_%d', s);
	savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
end

