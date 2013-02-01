function[] = plot_features(slide_or_chunk, time_window, peak_detect_appr)

% plot_features('chunk', 5, 1)
% plot_features('slide', 30, 1)

close all;

visible_flag = true;
pqrst_flag = true;
number_of_subjects = 3;

[subject_id, subject_session, subject_threshold] = get_subject_ids(number_of_subjects);
for s = 2:2
% for s = 1:number_of_subjects
	qt_length{s} = fetch_qt_length(subject_id{s}, slide_or_chunk, time_window, peak_detect_appr, [0:4], [8, 16, 32, -3],...
					visible_flag, pqrst_flag);

	make_plots(subject_id{s}, time_window, peak_detect_appr, slide_or_chunk, qt_length{s}, 'PR length',...
				(qt_length{s}.r_point(:, 1) - qt_length{s}.p_point(:, 1)), 'pr');
	make_plots(subject_id{s}, time_window, peak_detect_appr, slide_or_chunk, qt_length{s}, 'RT length',...
				(qt_length{s}.t_point(:, 1) - qt_length{s}.r_point(:, 1)), 'rt');
	make_plots(subject_id{s}, time_window, peak_detect_appr, slide_or_chunk, qt_length{s}, 'PT length',...
				(qt_length{s}.t_point(:, 1) - qt_length{s}.p_point(:, 1)), 'pt');
	make_plots(subject_id{s}, time_window, peak_detect_appr, slide_or_chunk, qt_length{s}, 'QT length',...
				(qt_length{s}.t_point(:, 1) - qt_length{s}.q_point(:, 1)), 'qt');
	make_plots(subject_id{s}, time_window, peak_detect_appr, slide_or_chunk, qt_length{s}, 'QT_c length',...
				(qt_length{s}.t_point(:, 1) - qt_length{s}.q_point(:, 1)).*sqrt(qt_length{s}.rr_length), 'qtc');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_plots(subject_id, time_window, peak_detect_appr, slide_or_chunk, qt_length, ylabel_str, feature, feature_name)

dosage_levels = get_project_settings('dosage_levels');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
dos_marker_str = {'ro', 'bo', 'go', 'mo'};
h1 = [];

figure(); set(gcf, 'Position', [70, 10, 1300, 650]);
plot(find(feature), feature(find(feature)), 'k');
hold on; grid on;
for d = 1:length(dosage_levels)
	dosage_idx = find(qt_length.dosage(:, end) == dosage_levels(d));
	qt_idx = find(feature(dosage_idx, 1) > 0);
	plot_x = dosage_idx(qt_idx);
	plot_y = feature(plot_x, 1);
	h = plot(plot_x, plot_y, dos_marker_str{d}, 'MarkerFaceColor', dos_marker_str{d}(1));
	h1 = [h1, h];
end
y_vals = linspace(min(feature), max(feature)+5, 100);
plot(find(qt_length.infusion_presence), y_vals(98), 'r*');
plot(find(qt_length.click_presence), y_vals(100), 'k*');
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
file_name = sprintf('%s/%s/%s_%s%d_peak%d_%s', plot_dir, subject_id, subject_id, slide_or_chunk,...
						time_window, peak_detect_appr, feature_name);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[info_per_chunk] = fetch_qt_length(subject_id, slide_or_chunk, time_window, peak_detect_appr, varargin)

data_dir = get_project_settings('data');
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
infusion_indices = find(behav_mat(:, 8) == 1);
click_indices = find(behav_mat(:, 7) == 1);

exp_sessions = get_project_settings('exp_sessions');
dosage_levels = get_project_settings('dosage_levels');
result_dir = get_project_settings('results');
this_subj_exp_sessions = get_project_settings('exp_sessions');
this_subj_dosage_levels = get_project_settings('dosage_levels');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
visible_flag = false;
pqrst_flag = false;

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
start_hh_col = nInterpolatedFeatures + 2;
start_mm_col = nInterpolatedFeatures + 3;
end_hh_col = nInterpolatedFeatures + 4;
end_mm_col = nInterpolatedFeatures + 5;
nSamples_col = nInterpolatedFeatures + 6;
dosage_col = nInterpolatedFeatures + 7;

if length(varargin) > 0
	switch length(varargin)
	case 1
		this_subj_exp_sessions = varargin{1};
	case 2
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
	case 3
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
		visible_flag = varargin{3};
	case 4
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
		visible_flag = varargin{3};
		pqrst_flag = varargin{4};
	end
end

switch slide_or_chunk
case 'chunk'
	if ~exist(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', time_window)))
		error(sprintf('File ''chunks_%d_min.mat'' does not exist!', time_window));
	else
		load(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', time_window)));
		window_data = chunks_m_min;
	end
case 'slide'
	if ~exist(fullfile(result_dir, subject_id, sprintf('sliding_%dsec_win.mat', time_window)))
		error(sprintf('File ''sliding_%dsec_win.mat'' does not exist!', time_window));
	else
		load(fullfile(result_dir, subject_id, sprintf('sliding_%dsec_win.mat', time_window)));
		window_data = sliding_ksec_win;
	end
end

%{
if visible_flag
	figure();
else
	figure('visible', 'off');
end
set(gcf, 'Position', [70, 10, 1300, 650]);
%}

info_per_chunk = struct();
info_per_chunk.p_point = [];
info_per_chunk.q_point = [];
info_per_chunk.r_point = [];
info_per_chunk.s_point = [];
info_per_chunk.t_point = [];
info_per_chunk.nSamples = [];
info_per_chunk.infusion_presence = [];
info_per_chunk.click_presence = [];
info_per_chunk.rr_length = [];
info_per_chunk.dosage = [];

image_format = get_project_settings('image_format');

for e = 1:length(this_subj_exp_sessions)
	switch slide_or_chunk
	case 'slide'
		sl_ch_str = 'sec sliding window';
	case 'chunk'
		sl_ch_str = 'minute window';
	end
	title(sprintf('%s, session=%d, %d %s', get_project_settings('strrep_subj_id', subject_id),...
								this_subj_exp_sessions(e), time_window, sl_ch_str));
	hold on;
	legend_str = {};
	legend_cntr = 1;
	if pqrst_flag
		individual_chunks =...
			window_data{1, exp_sessions == this_subj_exp_sessions(e)}.pqrst;
	else
		individual_chunks =...
			window_data{1, exp_sessions == this_subj_exp_sessions(e)}.rr;
	end

	colors = jet(size(individual_chunks, 1));
	for d = 1:length(this_subj_dosage_levels)
	for s = 1:size(individual_chunks, 1)
	if any(individual_chunks(s, dosage_col) == this_subj_dosage_levels(d))
		%legend_str{legend_cntr} = sprintf('%d|%02d:%02d-%02d:%02d,%d samples',...
		%		individual_chunks(s, dosage_col),...
		%		individual_chunks(s, start_hh_col), individual_chunks(s, start_mm_col),...
		%		individual_chunks(s, end_hh_col), individual_chunks(s, end_mm_col),...
		%		individual_chunks(s, nSamples_col));
		if legend_cntr == 1
			grid on;
			xlim([0, get_project_settings('nInterpolatedFeatures')]);
			ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
			if strcmp(subject_id, 'P20_048'), ylim([-1, 0.5]); end
			if strcmp(subject_id, 'P20_058'), ylim([-2, 2]); end
		end
		legend_cntr = legend_cntr + 1;
		% legend(legend_str);
		figure('visible', 'off'); hold on;
		[p_point, q_point, r_point, s_point, t_point] = find_qt_points(peak_detect_appr, individual_chunks(s, ecg_col),...
					individual_chunks(s, nSamples_col), colors(s, :), visible_flag);
		if ~isempty(find(q_point)) & ~isempty(find(t_point))
			plot(individual_chunks(s, ecg_col), 'color', colors(s, :));
			title(sprintf('Avg. over %d samples in this window', individual_chunks(s, end-1)));
			file_name = sprintf('/home/anataraj/Desktop/temp/plot_e%d_d%d_s%d', e, d, s);
			savesamesize(gcf, 'file', file_name, 'format', image_format);
		end
		close all;
		
		infusion_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
					behav_mat(infusion_indices, 3:4));
		click_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
					behav_mat(click_indices, 3:4));

		info_per_chunk.p_point = [info_per_chunk.p_point; p_point];
		info_per_chunk.q_point = [info_per_chunk.q_point; q_point];
		info_per_chunk.r_point = [info_per_chunk.r_point; r_point];
		info_per_chunk.s_point = [info_per_chunk.s_point; s_point];
		info_per_chunk.t_point = [info_per_chunk.t_point; t_point];
		info_per_chunk.nSamples = [info_per_chunk.nSamples; individual_chunks(s, nSamples_col)];
		info_per_chunk.infusion_presence = [info_per_chunk.infusion_presence; infusion_presence];
		info_per_chunk.click_presence = [info_per_chunk.click_presence; click_presence];
		info_per_chunk.rr_length = [info_per_chunk.rr_length; individual_chunks(s, rr_col)];
		info_per_chunk.dosage = [info_per_chunk.dosage; individual_chunks(s, dosage_col)];
	end
	end
	end
end

file_name = sprintf('%s/%s/%s_%s%d_peak%d_detection', get_project_settings('plots'), subject_id, subject_id,...
							slide_or_chunk, time_window, peak_detect_appr);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[p_point, q_point, r_point, s_point, t_point] = find_qt_points(peak_detect_appr, individual_chunks, nSamples, set_colors, visible_flag)

p_point = []; q_point = []; r_point = []; s_point = []; t_point = [];

[maxtab, mintab] = peakdet(individual_chunks, 0.2);

if size(maxtab, 1) >= 1 & size(mintab, 1) >= 1;
	if maxtab(1, 1) == 1
		maxtab = maxtab(maxtab(:, 1) > 2, :); % leaving out the first point
	end
	if ~isempty(maxtab)
		mintab = mintab(mintab(:, 1) > maxtab(1, 1), :); % retaining the troughs only after the first peak
	end
	if ~isempty(maxtab) & ~isempty(mintab) % only when both exist
		switch get_project_settings('peak_det', peak_detect_appr)
		case 'strict-3-2'
			if size(maxtab, 1) == 3 & size(mintab, 1) == 2
				p_point = maxtab(1, :);
				q_point = mintab(1, :);
				r_point = maxtab(2, :);
				s_point = mintab(2, :);
				t_point = maxtab(end, :);
			end
		%{
		case 'no-checks'
			q_point = mintab(1, :);
			t_point = maxtab(maxtab(:, 1) > 70, :);
		case 'mean-whole-signal' % thresholding by the mean of the whole signal
			hold_mintab = find(mintab(:, 2) < mean(individual_chunks));
			q_point = mintab(hold_mintab(1), :);
			hold_maxtab = find(maxtab(:, 2) > mean(individual_chunks));
			t_point = maxtab(hold_maxtab(end), :);
		case 'mean-first-last' % thresholding the mean of the first and last point
			hold_mintab = find(mintab(:, 2) < mean([individual_chunks(1), individual_chunks(end)]));
			q_point = mintab(hold_mintab(1), :);
			hold_maxtab = find(maxtab(:, 2) > mean([individual_chunks(1), individual_chunks(end)]));
			t_point = maxtab(hold_maxtab(end), :);
		%}
		otherwise, error('Invalid peak detection technique');
		end

		if size(q_point, 1) == 1 & size(t_point, 1) == 1;
			plot(p_point(1, 1), p_point(1, 2), 'r*', 'MarkerSize', 10);
			plot(q_point(1, 1), q_point(1, 2), 'g*', 'MarkerSize', 10);
			plot(r_point(1, 1), r_point(1, 2), 'b*', 'MarkerSize', 10);
			plot(s_point(1, 1), s_point(1, 2), 'k*', 'MarkerSize', 10);
			plot(t_point(1, 1), t_point(1, 2), 'm*', 'MarkerSize', 10);
			%{
			h1=plot(q_point(1, 1), q_point(1, 2), '*', 'color', set_colors, 'MarkerSize', 10);
			hAnnotation = get(h1, 'Annotation');
			hLegendEntry = get(hAnnotation', 'LegendInformation');
			set(hLegendEntry, 'IconDisplayStyle', 'off');

			h2=plot(t_point(1, 1), t_point(1, 2), 's', 'color', set_colors, 'MarkerSize', 10);
			hAnnotation = get(h2, 'Annotation');
			hLegendEntry = get(hAnnotation', 'LegendInformation');
			set(hLegendEntry, 'IconDisplayStyle', 'off');
			%}
		else
			disp(sprintf('Missing either q or t point'));
			q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
		end
	else
		disp(sprintf('Missing either q or t point'));
		q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
	end
	% if visible_flag, pause(0.5); end
else
	disp(sprintf('No peaks detected'));
	q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[event_presence_absence] = detect_event(chunk_start_end, behav_event_data)

start_hh = chunk_start_end(1);
start_mm = chunk_start_end(2);
end_hh = chunk_start_end(3);
end_mm = chunk_start_end(4);
event_presence_absence = sum((behav_event_data(:, 1) > start_hh |...
			      behav_event_data(:, 1) == start_hh & behav_event_data(:, 2) >= start_mm) &...
    		   	     (behav_event_data(:, 1) < end_hh |...
			      behav_event_data(:, 1) == end_hh & behav_event_data(:, 2) < end_mm) );

