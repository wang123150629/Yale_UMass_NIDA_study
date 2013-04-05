function[] = make_plots(which_plot, varargin)

close all;

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
plot_dir = get_project_settings('pdf_result_location');
subject_id = 'P20_040';
subject_sensor = 'Sensor_1';
subject_timestamp = '2012_06_27-09_21_36';
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
rr_thresholds = 0.05;
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');

switch which_plot
case 1
	ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
						sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

	y = ecg_mat(6.5e+5:9e+5-1, 7) .* 0.001220703125;
	x = 1:length(y);
	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(x, y, 'k-');
	xlabel('Time(seconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	% xlabel('Time(milliseconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');

	x_ticks = (str2num(get(gca, 'XTickLabel')) * 10^5) / 250;
	% x_ticks = (str2num(get(gca, 'XTickLabel')) * 10^5) * 4;
	x_ticks(1) = 1;
	set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	set(gca, 'YTick', 0:5, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

	title(sprintf('Sensor dropout'), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');

	file_name = sprintf('%s/sensor_dropout', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure
case 2
	cocn_slide30_win = load(fullfile(result_dir, subject_id, 'cocn_slide30_win.mat'));
	cocn_pqrst_peaks_slide30 = load(fullfile(result_dir, subject_id, 'cocn_pqrst_peaks_slide30.mat'));
	base_idx = find(cocn_slide30_win.pqrst_mat(:, end) == 0 & cocn_slide30_win.pqrst_mat(:, end-1) == -3 &...
			cocn_pqrst_peaks_slide30.p_point(:, 1) > 0);
	fix8_idx = find(cocn_slide30_win.pqrst_mat(:, end) == 1 & cocn_slide30_win.pqrst_mat(:, end-1) == 8 &...
			cocn_pqrst_peaks_slide30.p_point(:, 1) > 0);
	fix16_idx = find(cocn_slide30_win.pqrst_mat(:, end) == 1 & cocn_slide30_win.pqrst_mat(:, end-1) == 16 &...
			cocn_pqrst_peaks_slide30.p_point(:, 1) > 0);
	fix32_idx = find(cocn_slide30_win.pqrst_mat(:, end) == 1 & cocn_slide30_win.pqrst_mat(:, end-1) == 32 &...
			cocn_pqrst_peaks_slide30.p_point(:, 1) > 0);

	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(cocn_slide30_win.pqrst_mat(base_idx(round_to(size(base_idx, 1) / 2, 0)), 1:100), 'r-', 'LineWidth', 2);
	hold on; grid on; ylim([-4, 5.5]);
	plot(cocn_slide30_win.pqrst_mat(fix8_idx(round_to(size(fix8_idx, 1) / 2, 0)), 1:100), 'g-', 'LineWidth', 2);
	plot(cocn_slide30_win.pqrst_mat(fix16_idx(round_to(size(fix16_idx, 1) / 2, 0)), 1:100), 'b-', 'LineWidth', 2);
	plot(cocn_slide30_win.pqrst_mat(fix32_idx(round_to(size(fix32_idx, 1) / 2, 0)), 1:100), 'k-', 'LineWidth', 2);
	hlegend = legend('Baseline', 'Fix 8mg', 'Fix 16mg', 'Fix 32mg');
	set(hlegend, 'FontSize', le_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Waveform features', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('standardized millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	x_ticks = get(gca, 'XTick');
	x_ticks(1) = 1;
	set(gca, 'XTick', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title(sprintf('Sample waveforms'), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');

	file_name = sprintf('%s/ecg_sample_waveforms', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure

case 3
	subject_id = 'P20_040';
	tt = 40;
	file_name = 'junk_heart_rate';
	label_pos = [650, 3200, 4700, 6627, 17203]; % for 3rd subject
	% label_pos = [450, 1010, 1110, 1600, 6627]; % for 6th subject

	cocn_preprocessed_data = load(fullfile(result_dir, subject_id, 'cocn_preprocessed_data.mat'));
	% baseline session
	heart_rate = cocn_preprocessed_data.preprocessed_data{1}.valid_rr_intervals';
	% fixed session
	heart_rate = [heart_rate, cocn_preprocessed_data.preprocessed_data{2}.valid_rr_intervals'];
	% first blinded session
	heart_rate = [heart_rate, cocn_preprocessed_data.preprocessed_data{3}.valid_rr_intervals'];
	% second blinded session
	heart_rate = [heart_rate, cocn_preprocessed_data.preprocessed_data{4}.valid_rr_intervals'];
	% session_boundaries = [session_boundaries, length(heart_rate)];

	heart_rate = (1000 * 60) ./ (4 .* heart_rate);

	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(heart_rate, 'k-'); hold on;

	x1 = repmat(session_boundaries, length(tt-5:1:150), 1);
	y1 = repmat((tt-5:1:150)', 1, length(session_boundaries));
	plot(x1, y1, 'color', [108, 123, 139]./255, 'LineStyle', '.', 'LineWidth', 3);

	ylim([tt-10, 150]); xlim([1, length(heart_rate)]);
	set(gca, 'XTickLabel', '');
	xlabel('Duration of Experiment(~6.5 hours)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('Heart rate(bpm)', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

	text(label_pos(1), tt, 'B', 'FontSize', 16, 'FontWeight', 'b', 'FontName', 'Times');
	text(label_pos(2), tt, '8', 'FontSize', 16, 'FontWeight', 'b', 'FontName', 'Times');
	text(label_pos(3), tt-7, '16', 'FontSize', 16, 'FontWeight', 'b', 'FontName', 'Times');
	text(label_pos(4), tt, '32', 'FontSize', 16, 'FontWeight', 'b', 'FontName', 'Times');
	text(label_pos(5), tt, 'SA', 'FontSize', 16, 'FontWeight', 'b', 'FontName', 'Times');

	file_name = sprintf('%s/%s', plot_dir, file_name);
	saveas(gcf, file_name, 'pdf') % Save figure

	%{
	tmp = round_to(diff(session_boundaries) / 2, 0);
	label_pos = session_boundaries(1:3) - tmp;
	label_pos = [label_pos, session_boundaries(3) + tmp(end)];
	label_pos = [label_pos, session_boundaries(end)+round_to((length(heart_rate) - session_boundaries(end)) / 2, 0)];
	label_pos(2) = 3100;
	label_pos(3) = label_pos(3) - 70;
	label_pos(4) = label_pos(4) - 500;
	label_pos = [100, session_boundaries + 100];
	label_pos = [100, 1200, 11300, 11400, 11500];
	%}
	% session_boundaries = [];
	% session_boundaries = [session_boundaries, length(heart_rate)];
	% session_boundaries = [session_boundaries, session_boundaries(length(session_boundaries))+...
	% 			length(find(cocn_preprocessed_data.preprocessed_data{2}.dosage_labels == 8))];
	% session_boundaries = [session_boundaries, session_boundaries(length(session_boundaries))+...
	% 			length(find(cocn_preprocessed_data.preprocessed_data{2}.dosage_labels == 16))];
	% session_boundaries = [session_boundaries, session_boundaries(length(session_boundaries))+...
	% 			length(find(cocn_preprocessed_data.preprocessed_data{2}.dosage_labels == 32))];
	%session_boundaries = [session_boundaries, session_boundaries(length(session_boundaries))+...
	%			length(find(cocn_preprocessed_data.preprocessed_data{2}.dosage_labels == -3))];

case 4
	ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
						sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
	y1 = ecg_mat(862460:863459, end) .* 0.001220703125;
	x1 = 1:length(y1);

	y2 = ecg_mat(862391:862391+7500, end) .* 0.001220703125;
	[rr, rs] = rrextract(y2, raw_ecg_mat_time_res, rr_thresholds);
	rr_start_end = [rr(1:end-1); rr(2:end)-1]';
	wave_window = [];
	for s = 1:size(rr_start_end, 1)
		y_length = length(y2(rr_start_end(s, 1):rr_start_end(s, 2)));
		yi = linspace(1, y_length, nInterpolatedFeatures);
		interpol_data = interp1(1:y_length, y2(rr_start_end(s, 1):rr_start_end(s, 2)), yi, 'pchip');
		wave_window = [wave_window; interpol_data];
	end

	nSamples = size(wave_window, 1);
	wave_window = [wave_window(1:nSamples-1, (nInterpolatedFeatures/2)+1:nInterpolatedFeatures),...
		       wave_window(2:nSamples, 1:nInterpolatedFeatures/2)];

	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(x1, y1, 'k-', 'LineWidth', 2);
	xlim([0, length(x1)]); ylim([2.40, 2.62]);
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks(1, [1, 3, 5]), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	x_ticks = str2num(get(gca, 'XTickLabel')) * 4;
	x_ticks(1) = 1;
	set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Time(milliseconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title(sprintf('Noisy ECG'), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	file_name = sprintf('%s/noisy_ecg', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure

	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(1:nInterpolatedFeatures, mean(wave_window, 1), 'k-', 'LineWidth', 2);
	ylim([2.40, 2.62]);
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks(1, [1, 3, 5]), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	x_ticks = get(gca, 'XTick');
	x_ticks(1) = 1;
	set(gca, 'XTick', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	% xlabel('Waveform features', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Time (std. units)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title(sprintf('ECG Sample'), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	file_name = sprintf('%s/window_ecg', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure

case 5
	ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
						sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

	y = ecg_mat(:, 7) .* 0.001220703125;
	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(y(1114000:1114000+7500), 'k-')
	ylim([2.35, 2.67]); xlim([0, length(1114000:1114000+7500)]);
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks(1, [1, 3, 5, 7]), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	x_ticks = str2num(get(gca, 'XTickLabel')) * 4;
	x_ticks(1) = 1;
	set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Time(milliseconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	title(sprintf('Baseline Drift'), 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	file_name = sprintf('%s/baseline_shift', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure
	
	%{
	plot(y(2116000:2121500))
	y_idx = 1:200:length(y);
	y_start_end = [y_idx(1:end-1); y_idx(2:end)-1]';
	avg_ecg_val = NaN(1, size(y_start_end, 1));
	for s = 1:size(y_start_end, 1)
		avg_ecg_val(1, s) = mean(y(y_start_end(s, 1):y_start_end(s, 2)));
	end
	%}
case 6
	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
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
	title(sprintf('All windows + peak detection'), 'fontweight', 'bold', 'fontsize', 12);
	legend([h1, h2, h3, h4, h5], 'P peak', 'Q trough', 'R peak', 'S trough', 'T peak');
	
case 7
	exer_preprocessed_data = load(fullfile(result_dir, 'P20_060', 'exer_preprocessed_data.mat'));
	heart_rate = exer_preprocessed_data.preprocessed_data{1}.valid_rr_intervals';
	heart_rate = (1000 * 60) ./ (4 .* heart_rate);

	figure();
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	plot(heart_rate, 'k-'); hold on;
	ylim([50, 150]); xlim([1, length(heart_rate)]);
	set(gca, 'XTickLabel', '');
	xlabel('Duration of Experiment(~15 mins)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('Heart rate(bpm)', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	y_ticks = get(gca, 'YTick');
	set(gca, 'YTick', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

	file_name = sprintf('%s/subj6_exer_heart_rate', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure

case 8
	peaks_data = load(fullfile(result_dir, subject_id, 'cocn_pqrst_peaks_slide30.mat'));
	window_data = load(fullfile(result_dir, subject_id, 'cocn_slide30_win.mat'));
	window_data = window_data.pqrst_mat;
	assert(size(window_data, 1) == size(peaks_data.p_point, 1));
	nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
	rr_length_col = nInterpolatedFeatures + 1;
	pt_dist_col = nInterpolatedFeatures + 2;
	dos_col = size(window_data, 2) - 1;
	exp_sess_col = size(window_data, 2);
	loaded_data = [window_data(:, 1:rr_length_col),...
			(peaks_data.t_point(:, 1) - peaks_data.p_point(:, 1)),...
			(peaks_data.t_point(:, 1) - peaks_data.r_point(:, 1)),...
			(peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)),...
			((peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)) .* sqrt(window_data(:, rr_length_col))),...
			(peaks_data.r_point(:, 1) - peaks_data.p_point(:, 1)),...
			(peaks_data.s_point(:, 1) - peaks_data.q_point(:, 1)),...
			peaks_data.p_point(:, 2),...
			peaks_data.q_point(:, 2),...
			peaks_data.r_point(:, 2),...
			peaks_data.s_point(:, 2),...
			peaks_data.t_point(:, 2)];

	% RR, T, QS, PR, QT, QTc
	target_feats = [nInterpolatedFeatures + 1, nInterpolatedFeatures + 12, nInterpolatedFeatures + 7, nInterpolatedFeatures + 6,...
			nInterpolatedFeatures + 4, nInterpolatedFeatures + 5];
	title_str = {'RR', 'T', 'QS', 'PR', 'QT', 'QTc'};
	figure();
	set(gcf, 'PaperPosition', [0 0 8 4]);
	set(gcf, 'PaperSize', [8 4]);
	for t = 1:length(target_feats)
		y_vals = [];
		switch t
		case 2,	nDigits = 2; nBins = 20;
		case 3, y_vals = unique(loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t))); nBins = length(y_vals);
		case 4, y_vals = unique(loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t))); nBins = length(y_vals);
		case 5, y_vals = unique(loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t))); nBins = length(y_vals);
		otherwise, nDigits = 0; nBins = 20;
		end
		counts = NaN(nBins, 5);

		if isempty(varargin), varargin{1} = 1; end
		if isempty(y_vals)
			switch varargin{1}
			case 1
				y_vals = round_to(linspace(min(loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t))),...
				 	 max(loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t))), nBins), nDigits);
			case 2
				y_vals = round_to(linspace(quantile(loaded_data(loaded_data(:, pt_dist_col) > 0,...
					target_feats(t)), 0.05), quantile(loaded_data(loaded_data(:, pt_dist_col) > 0,...
					target_feats(t)), 0.95), nBins), nDigits);
			case 3
				data = loaded_data(loaded_data(:, pt_dist_col) > 0, target_feats(t));
				a = mean(data) - 4*std(data);
				b = mean(data) + 4*std(data);
				y_vals = round_to(linspace(a, b, nBins), nDigits);
			end
		end

		for d = 1:5
			switch d
			case 1, target_idx = find(window_data(:, exp_sess_col) == 0);
			case 2, target_idx = intersect(find(window_data(:, exp_sess_col) == 1),...
					               find(window_data(:, dos_col) == 8));
			case 3, target_idx = intersect(find(window_data(:, exp_sess_col) == 1),...
					               find(window_data(:, dos_col) == 16));
			case 4, target_idx = intersect(find(window_data(:, exp_sess_col) == 1),...
					               find(window_data(:, dos_col) == 32));
			case 5, target_idx = find(window_data(:, exp_sess_col) == 0);
				target_idx = setdiff(1:size(window_data, 1), target_idx);
			end
			target_idx = intersect(target_idx, find(loaded_data(:, pt_dist_col) > 0));
			% counts(:, d) = hist(loaded_data(target_idx, target_feats(t)), nBins);
			counts(:, d) = hist(loaded_data(target_idx, target_feats(t)), y_vals);
			counts(:, d) = counts(:, d) ./ sum(counts(:, d));
		end

		subplot(2, 3, t); imagesc(1 - counts); colormap bone
		y_ticks = get(gca, 'YTick');
		set(gca, 'YTick', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
		set(gca, 'YTickLabel', y_vals(y_ticks), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
		% x_ticks = get(gca, 'XTick');
		% set(gca, 'XTick', x_ticks, 'FontSize', 8, 'FontWeight', 'b', 'FontName', 'Times');
		set(gca, 'XTickLabel', {'B', '8', '16', '32', 'A'}, 'FontSize', 8, 'FontWeight', 'b', 'FontName', 'Times');
		title(title_str{t}, 'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');		
	end

	file_name = sprintf('%s/know_feat_heatmap', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure

otherwise, error('Invalid plot number!');

end

