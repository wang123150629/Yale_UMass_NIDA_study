function[] = plot_distance_bw_peaks(subject_id, event, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag)

% plot_distance_bw_peaks('P20_040', 'cocn', 'slide', 30, 4, true)
% plot_distance_bw_peaks('P20_040', 'cocn', 'chunk', 5, 4, true)

close all;

result_dir = get_project_settings('results');

window_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s%d_win.mat', event, slide_or_chunk, time_window)));
if pqrst_flag
	window_data = window_data.pqrst_mat;
	pqrst_rr_peaks_str = 'pqrst';
else
	window_data = window_data.rr_mat;
	pqrst_rr_peaks_str = 'rr';
end
peaks_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s_peaks_%s%d.mat', event, pqrst_rr_peaks_str,...
									slide_or_chunk, time_window)));

assert(size(window_data, 1) == size(peaks_data.p_point, 1));
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
rr_length_col = nInterpolatedFeatures + 1;
dosage_col = size(window_data, 2) - 1;

make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'PR length',...
			(peaks_data.r_point(:, 1) - peaks_data.p_point(:, 1)), 'pr', event);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'RT length',...
			(peaks_data.t_point(:, 1) - peaks_data.r_point(:, 1)), 'rt', event);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'PT length',...
			(peaks_data.t_point(:, 1) - peaks_data.p_point(:, 1)), 'pt', event);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'QT length',...
			(peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)), 'qt', event);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'QT_c length',...
			(peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)).*sqrt(window_data(:, rr_length_col)), 'qtc', event);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, dosage_info,...
					ylabel_str, feature, feature_name, event)

dosage_levels = get_from_subj_profile(subject_id, event, 'dosage_levels');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
dos_marker_str = {'ro', 'bo', 'go', 'mo'};
h1 = [];

figure(); set(gcf, 'Position', [70, 10, 1300, 650]);
plot(find(feature), feature(find(feature)), 'k');
hold on; grid on;

for d = 1:length(dosage_levels)
	dosage_idx = find(dosage_info == dosage_levels(d));
	qt_idx = find(feature(dosage_idx, 1) > 0);
	plot_x = dosage_idx(qt_idx);
	plot_y = feature(plot_x, 1);
	h = plot(plot_x, plot_y, dos_marker_str{d}, 'MarkerFaceColor', dos_marker_str{d}(1));
	h1 = [h1, h];
end
y_vals = linspace(min(feature), max(feature)+5, 100);
plot(find(peaks_data.infusion_presence), y_vals(98), 'r*');
plot(find(peaks_data.click_presence), y_vals(100), 'k*');
ylabel(ylabel_str);
switch slide_or_chunk
case 'slide'
	xlabel(sprintf('Exp. sess in %d sec sliding window', time_window));
case 'chunk'
	xlabel(sprintf('Exp. sess in %d minute window', time_window));
end
set(gca, 'XTickLabel', '');
legend(h1, '8mg', '16mg', '32mg', 'baseline', 'Location', 'SouthEast', 'Orientation', 'Horizontal');
title(sprintf('%s', get_project_settings('strrep_subj_id', subject_id)));
file_name = sprintf('%s/%s/%s%d_peak%d_%s', plot_dir, subject_id, slide_or_chunk,...
						time_window, peak_detect_appr, feature_name);
savesamesize(gcf, 'file', file_name, 'format', image_format);

