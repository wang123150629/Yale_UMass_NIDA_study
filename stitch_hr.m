function[] = stitch_hr()

close all;

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');

event = 1;
subject_id = 'P20_040';
subject_profile = subject_profiles(subject_id);
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
subject_threshold = subject_profile.events{event}.rr_thresholds;
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');

crf_rr_mat = load('P20_040_crf_lab_peaks.mat');
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
summary_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
			sprintf('%s_Summary.csv', subject_timestamp)), 1, 0);
summary_mat_valid_hr = find(summary_mat(:, 7) > 0);

% ecg_mat = ecg_mat(3.5*10^6:end, :);
% ecg_mat = ecg_mat(1:2.39*10^6+1, :);
ecg_mat(:, end) = ecg_mat(:, end) .* 0.001220703125;
st_end = [1:7500:size(ecg_mat, 1)];
st_end = [st_end(1:end-1); st_end(2:end)-1]';
st_end = [st_end; st_end(end, 2)+1, size(ecg_mat, 1)];

rr_hr = zeros(1, size(st_end, 1));
crf_hr = zeros(1, size(st_end, 1));
summ_hr = zeros(1, size(st_end, 1));
behav_hr = zeros(1, size(st_end, 1));
for s = 1:size(st_end, 1)
	target_idx = st_end(s, 1):st_end(s, 2);
	[rr, rs] = rrextract(ecg_mat(target_idx, end), 250, subject_threshold);
	rr_start_end = [rr(1:end-1); rr(2:end)-1]';
	rr_hr_tmp = rr_start_end(:, 2) - rr_start_end(:, 1) + 1;
	% rr_hr_tmp = rr_hr_tmp(rr_hr_tmp > cut_off_heart_rate(1) & rr_hr_tmp <= cut_off_heart_rate(2));
	mean_rr_hr = mean(rr_hr_tmp);
	rr_hr(1, s) = (1000 ./ (mean_rr_hr .* 4)) .* 60;
	if rr_hr(1, s) > 150 | rr_hr(1, s) < 50
		fprintf('rr:%d:%d:%0.4f to %d:%d:%0.4f\n', ecg_mat(target_idx(1), 4:6), ecg_mat(target_idx(end), 4:6));
	end

	crf_rr = find(crf_rr_mat.temp(target_idx) == 3);
	crf_start_end = [crf_rr(1:end-1); crf_rr(2:end)-1]';
	crf_hr_tmp = crf_start_end(:, 2) - crf_start_end(:, 1) + 1;
	% crf_hr_tmp = crf_hr_tmp(crf_hr_tmp > cut_off_heart_rate(1) & crf_hr_tmp <= cut_off_heart_rate(2));
	mean_crf_hr = mean(crf_hr_tmp);
	crf_hr(1, s) = (1000 ./ (mean_crf_hr .* 4)) .* 60;
	if crf_hr(1, s) > 150 | crf_hr(1, s) < 50
		fprintf('crf:%d:%d:%0.4f to %d:%d:%0.4f\n', ecg_mat(target_idx(1), 4:6), ecg_mat(target_idx(end), 4:6));
	end

	summ_idx_1 = find(summary_mat(:, 4) == ecg_mat(target_idx(1), 4) &...
		    summary_mat(:, 5) == ecg_mat(target_idx(1), 5) &...
		    summary_mat(:, 6) >= ecg_mat(target_idx(1), 6));
	summ_idx_2 = find(summary_mat(:, 4) == ecg_mat(target_idx(end), 4) &...
		    summary_mat(:, 5) == ecg_mat(target_idx(end), 5) &...
		    summary_mat(:, 6) <= ecg_mat(target_idx(end), 6));
	summ_idx = summ_idx_1(1):summ_idx_2(end);
	if ~isempty(intersect(summ_idx, summary_mat_valid_hr))
		summ_hr(1, s) = mean(summary_mat(intersect(summ_idx, summary_mat_valid_hr), 7));
	end

	behav_idx_1 = find(behav_mat(:, 3) == ecg_mat(target_idx(1), 4) &...
		           behav_mat(:, 4) == ecg_mat(target_idx(1), 5));
	if ~isempty(behav_idx_1)
		behav_hr(1, s) = behav_mat(behav_idx_1, end);
	end
end

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(rr_hr, 'r'); hold on;
plot(crf_hr, 'b');
plot(summ_hr, 'k');
plot(behav_hr, 'mo', 'MarkerFaceColor', 'm');
ylim([50, 150]);
xlabel('Time(milliseconds)');
ylabel('Heart rate');
legend('ECGToolbox', 'CRF', 'Summary(Zephyr)', 'Behav(Phillips)');

image_format = get_project_settings('image_format');
file_name = sprintf('%s/sparse_coding/misc_plots/diff_hr_comp', plot_dir);
savesamesize(gcf, 'file', file_name, 'format', image_format);

