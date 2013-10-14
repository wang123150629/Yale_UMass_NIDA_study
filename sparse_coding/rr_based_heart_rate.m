function[rr, rr_intervals, heart_rate, trend] = rr_based_heart_rate(subject_id, ecg_mat, peak_thres)

result_dir = get_project_settings('results');
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');

[rr, rs] = rrextract(ecg_mat, raw_ecg_mat_time_res, peak_thres);
rr_start_end = [rr(1:end-1); rr(2:end)-1]';

rr_intervals = NaN(1, size(rr_start_end, 1));
for r = 1:size(rr_start_end, 1)
	rr_intervals(1, r) = length(rr_start_end(r, 1):rr_start_end(r, 2));
end
valid_heart_rate_idx = rr_intervals >= 100 & rr_intervals <= 300;
valid_rr_intervals = rr_intervals(valid_heart_rate_idx);
heart_rate = (1000 * 60) ./ (4 .* valid_rr_intervals);

waveforms = load(fullfile(result_dir, subject_id, 'cocn_slide30_win.mat'));
base_idx = waveforms.pqrst_mat(:, end) == 0 & waveforms.pqrst_mat(:, end-1) == -3;
pqrst_waveforms = waveforms.pqrst_mat(base_idx, 1:100);

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
ylim([-4, 7]); hold on;
% wavys_to_plot = 1:10:size(pqrst_waveforms, 1);
wavys_to_plot = 1:1:size(pqrst_waveforms, 1);
colormm = jet(length(wavys_to_plot));
for t = 1:length(wavys_to_plot)
	plot(pqrst_waveforms(wavys_to_plot(t), :), 'color', colormm(t, :));
	% pause(0.05);
end

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(heart_rate);
xlabel('Time(minutes)');
ylabel('Heart rate(bpm)');
hold on;
trend = conv(heart_rate, repmat(1/100, 1, 100), 'valid');
plot(trend, 'r-', 'LineWidth', 2);
trend = conv(heart_rate, repmat(1/200, 1, 200), 'valid');
plot(trend, 'g-', 'LineWidth', 2);
trend = conv(heart_rate, repmat(1/300, 1, 300), 'valid');
plot(trend, 'k-', 'LineWidth', 2);
trend = conv(heart_rate, repmat(1/400, 1, 400), 'valid');
plot(trend, 'm-', 'LineWidth', 2);
trend = conv(heart_rate, repmat(1/500, 1, 500), 'valid');
plot(trend, 'y-', 'LineWidth', 2);
legend('heart rate', '100', '200', '300', '400', '500');

%{
interpol_data = NaN(size(rr_start_end, 1), nInterpolatedFeatures);
xi = linspace(1, rr_intervals(1, r), nInterpolatedFeatures);
interpol_data(r, :) = interp1(1:rr_intervals(1, r), ecg_mat(rr_start_end(r, 1):rr_start_end(r, 2)), xi, 'pchip');
interpol_data = interpol_data(valid_heart_rate_idx, :);
waveform = [interpol_data(1:end-1, 51:100), interpol_data(2:end, 1:50)];
% The mean RR interval is 153. So this translates to 2 samples per second (153 x 4 millisecond per sample = 612 x 2 ~ 1000). By taking the average of every ten samples we get an estimate for approximately 5 seconds.
target_idx = [1:10:size(waveform, 1); 10:10:size(waveform, 1), size(waveform, 1)];

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
ylim([2, 3]); hold on;
colormm = jet(size(target_idx, 2));
for t = 1:size(target_idx, 2)
	plot(mean(waveform(target_idx(1, t):target_idx(2, t), :), 1), 'color', colormm(t, :));
	pause(0.05);
end
%}

