function[] = plot_distance_bw_peaks(subject_profile, event, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag)

% plot_distance_bw_peaks('P20_040', 'cocn', 'slide', 30, 4, true)
% plot_distance_bw_peaks('P20_040', 'cocn', 'chunk', 5, 4, true)

close all;

subject_id = subject_profile.subject_id;
dosage_levels = subject_profile.events{event}.dosage_levels;
event_label = subject_profile.events{event}.label;
file_name = subject_profile.events{event}.file_name;
result_dir = get_project_settings('results');

window_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s%d_win.mat', file_name, slide_or_chunk, time_window)));
if pqrst_flag
	window_data = window_data.pqrst_mat;
	pqrst_rr_peaks_str = 'pqrst';
else
	window_data = window_data.rr_mat;
	pqrst_rr_peaks_str = 'rr';
end
peaks_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s_peaks_%s%d.mat', file_name, pqrst_rr_peaks_str,...
									slide_or_chunk, time_window)));

assert(size(window_data, 1) == size(peaks_data.p_point, 1));
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
rr_length_col = nInterpolatedFeatures + 1;
dosage_col = size(window_data, 2) - 1;

make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'PR length',...
			(peaks_data.r_point(:, 1) - peaks_data.p_point(:, 1)), 'pr', event_label, dosage_levels,...
			file_name);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'RT length',...
			(peaks_data.t_point(:, 1) - peaks_data.r_point(:, 1)), 'rt', event_label, dosage_levels,...
			file_name);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'PT length',...
			(peaks_data.t_point(:, 1) - peaks_data.p_point(:, 1)), 'pt', event_label, dosage_levels,...
			file_name);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'QT length',...
			(peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)), 'qt', event_label, dosage_levels,...
			file_name);
make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, window_data(:, dosage_col), 'QT_c length',...
			(peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)).*sqrt(window_data(:, rr_length_col)), 'qtc',...
			event_label, dosage_levels, file_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, peaks_data, dosage_info,...
					ylabel_str, feature, feature_name, event_label, dosage_levels, file_name)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
dos_marker_str = {'ro', 'bo', 'go', 'mo', 'co'};
legend_str = {};
h1 = [];

figure('visible', 'off'); set(gcf, 'Position', [70, 10, 1300, 650]);
plot(find(feature), feature(find(feature)), 'k');
hold on; grid on;
dosage_cntr = 1;

for d = 1:length(dosage_levels)
	dosage_idx = find(dosage_info == dosage_levels(d));
	qt_idx = find(feature(dosage_idx, 1) > 0);

	if length(qt_idx) > 0
		switch dosage_levels(d)
		case 8, legend_str{dosage_cntr} = '8mg'; dosage_marker = dos_marker_str{1};
		case 16, legend_str{dosage_cntr} = '16mg'; dosage_marker = dos_marker_str{2};
		case 32, legend_str{dosage_cntr} = '32mg'; dosage_marker = dos_marker_str{3};
		case -3, legend_str{dosage_cntr} = 'baseline'; dosage_marker = dos_marker_str{4};
		case 0, legend_str{dosage_cntr} = '0mg'; dosage_marker = dos_marker_str{5};
		otherwise, error('Invalid dosage level!');
		end
		dosage_cntr = dosage_cntr + 1;
		plot_x = dosage_idx(qt_idx);
		plot_y = feature(plot_x, 1);
		h = plot(plot_x, plot_y, dosage_marker, 'MarkerFaceColor', dosage_marker(1));
		h1 = [h1, h];
	end
end
y_vals = linspace(min(feature), max(feature)+5, 100);
if ~isempty(find(peaks_data.infusion_presence))
	plot(find(peaks_data.infusion_presence), y_vals(98), 'r*');
end
if ~isempty(find(peaks_data.click_presence))
	plot(find(peaks_data.click_presence), y_vals(100), 'k*');
end
ylabel(ylabel_str);
switch slide_or_chunk
case 'slide'
	xlabel(sprintf('Exp. sess in %d sec sliding window', time_window));
case 'chunk'
	xlabel(sprintf('Exp. sess in %d minute window', time_window));
end
set(gca, 'XTickLabel', '');
legend(h1, legend_str, 'Location', 'SouthEast', 'Orientation', 'Horizontal');
title(sprintf('%s, %s', get_project_settings('strrep_subj_id', subject_id), event_label));

file_name = sprintf('%s/%s/%s_%s%d_peak%d_%s', plot_dir, subject_id, file_name, slide_or_chunk,...
						time_window, peak_detect_appr, feature_name);
savesamesize(gcf, 'file', file_name, 'format', image_format);

