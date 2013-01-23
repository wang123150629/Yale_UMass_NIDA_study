function[] = plot_qt_interval(how_many_minutes)

peak_detect_appr = 'no-checks';
visible_flag = false;
pqrst_flag = true;

close all;
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

number_of_subjects = 3;
[subject_id, subject_session, subject_threshold] = get_subject_ids(number_of_subjects);
dosage_levels = get_project_settings('dosage_levels');
for s = 1:number_of_subjects
	qt_length{s} = fetch_qt_length(subject_id{s}, how_many_minutes, peak_detect_appr, [0:4], [8, 16, 32, -3], visible_flag, pqrst_flag);
end

switch peak_detect_appr
case 'no-checks', peak_det_num = 1;
case 'mean-whole-signal', peak_det_num = 2;
case 'mean-first-last', peak_det_num = 3;
otherwise, error('Invalid peak detection technique');
end	

dos_marker_str = {'ro', 'bo', 'go', 'mo'};
for s = 1:number_of_subjects
	h1 = [];
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	valid_qt_dist = (qt_length{s}.t_point(:, 1) - qt_length{s}.q_point(:, 1));
	plot(find(valid_qt_dist), valid_qt_dist(find(valid_qt_dist)), 'k');
	hold on; grid on;
	for d = 1:length(dosage_levels)
		dosage_idx = find(qt_length{s}.dosage(:, end) == dosage_levels(d));
		qt_idx = find(qt_length{s}.t_point(dosage_idx, 1) - qt_length{s}.q_point(dosage_idx, 1) > 0);
		plot_x = dosage_idx(qt_idx);
		plot_y = qt_length{s}.t_point(plot_x, 1) - qt_length{s}.q_point(plot_x, 1);
		h = plot(plot_x, plot_y, dos_marker_str{d}, 'MarkerFaceColor', dos_marker_str{d}(1));
		h1 = [h1, h];
	end
	plot(find(qt_length{s}.infusion_presence), max(valid_qt_dist)+2, 'r*');
	plot(find(qt_length{s}.click_presence), max(valid_qt_dist)+3, 'k*');
	ylabel('QT length');
	xlabel(sprintf('Exp. sess in %d minute chunks', how_many_minutes));
	set(gca, 'XTickLabel', '');
	legend(h1, '8mg', '16mg', '32mg', 'baseline', 'Location', 'SouthEast', 'Orientation', 'Horizontal');
	title(sprintf('%s', get_project_settings('strrep_subj_id', subject_id{s})));
	file_name = sprintf('%s/%s/subj_%s_peak%d_qt_%d', plot_dir, subject_id{s}, subject_id{s}, peak_det_num, how_many_minutes);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

for s = 1:number_of_subjects
	h1 = [];
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	valid_qtc_dist = (qt_length{s}.t_point(:, 1) - qt_length{s}.q_point(:, 1)).*sqrt(qt_length{s}.rr_length);
	plot(find(valid_qtc_dist), valid_qtc_dist(find(valid_qtc_dist)), 'k');
	hold on; grid on;
	for d = 1:length(dosage_levels)
		dosage_idx = find(qt_length{s}.dosage(:, end) == dosage_levels(d));
		qt_idx = find(qt_length{s}.t_point(dosage_idx, 1) - qt_length{s}.q_point(dosage_idx, 1) > 0);
		plot_x = dosage_idx(qt_idx);
		plot_y = (qt_length{s}.t_point(plot_x, 1) - qt_length{s}.q_point(plot_x, 1))...
							.* sqrt(qt_length{s}.rr_length(plot_x));
		h = plot(plot_x, plot_y, dos_marker_str{d}, 'MarkerFaceColor', dos_marker_str{d}(1));
		h1 = [h1, h];
	end
	plot(find(qt_length{s}.infusion_presence), max(valid_qtc_dist)+10, 'r*');
	plot(find(qt_length{s}.click_presence), max(valid_qtc_dist)+20, 'k*');
	ylabel('QT_c length');
	xlabel(sprintf('Exp. sess in %d minute chunks', how_many_minutes));
	set(gca, 'XTickLabel', '');
	legend(h1, '8mg', '16mg', '32mg', 'baseline', 'Location', 'NorthEast', 'Orientation', 'Vertical');
	title(sprintf('%s', get_project_settings('strrep_subj_id', subject_id{s})));
	file_name = sprintf('%s/%s/subj_%s_peak%d_qtc_%d', plot_dir, subject_id{s}, subject_id{s}, peak_det_num, how_many_minutes);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[info_per_chunk] = fetch_qt_length(subject_id, how_many_minutes, peak_detect_appr, varargin)

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

if ~exist(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', how_many_minutes)))
	error(sprintf('File ''chunks_%d_min.mat'' does not exist!', how_many_minutes));
else
	load(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', how_many_minutes)));
end

if visible_flag
	figure();
else
	figure('visible', 'off');
end
set(gcf, 'Position', [10, 10, 1200, 800]);

info_per_chunk = struct();
info_per_chunk.q_point = [];
info_per_chunk.t_point = [];
info_per_chunk.nSamples = [];
info_per_chunk.infusion_presence = [];
info_per_chunk.click_presence = [];
info_per_chunk.rr_length = [];
info_per_chunk.dosage = [];

for e = 1:length(this_subj_exp_sessions)
	title(sprintf('%s, session=%d, %d minute intervals', get_project_settings('strrep_subj_id', subject_id),...
								this_subj_exp_sessions(e), how_many_minutes));
	hold on;
	legend_str = {};
	legend_cntr = 1;
	if pqrst_flag
		individual_chunks =...
			chunks_m_min{1, exp_sessions == this_subj_exp_sessions(e)}.pqrst_chunk_m_min_session;
	else
		individual_chunks =...
			chunks_m_min{1, exp_sessions == this_subj_exp_sessions(e)}.rr_chunk_m_min_session;
	end

	colors = jet(size(individual_chunks, 1));
	for d = 1:length(this_subj_dosage_levels)
	for s = 1:size(individual_chunks, 1)
	if any(individual_chunks(s, dosage_col) == this_subj_dosage_levels(d))
		plot(individual_chunks(s, ecg_col), 'color', colors(s, :));
		legend_str{legend_cntr} = sprintf('%d|%02d:%02d-%02d:%02d,%d samples',...
				individual_chunks(s, dosage_col),...
				individual_chunks(s, start_hh_col), individual_chunks(s, start_mm_col),...
				individual_chunks(s, end_hh_col), individual_chunks(s, end_mm_col),...
				individual_chunks(s, nSamples_col));
		if legend_cntr == 1
			grid on;
			xlim([0, get_project_settings('nInterpolatedFeatures')]);
			ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
			if strcmp(subject_id, 'P20_048'), ylim([-1, 0.5]); end
			if strcmp(subject_id, 'P20_058'), ylim([-2, 2]); end
		end
		legend_cntr = legend_cntr + 1;
		% legend(legend_str);
		[q_point, t_point] = find_qt_points(peak_detect_appr, individual_chunks(s, ecg_col),...
					individual_chunks(s, nSamples_col), colors(s, :), visible_flag);
		
		infusion_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
					behav_mat(infusion_indices, 3:4));
		click_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
					behav_mat(click_indices, 3:4));

		info_per_chunk.q_point = [info_per_chunk.q_point; q_point];
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
% file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[q_point, t_point] = find_qt_points(peak_detect_appr, individual_chunks, nSamples, set_colors, visible_flag)

[maxtab, mintab] = peakdet(individual_chunks, 0.2);
if size(maxtab, 1) >= 1 & size(mintab, 1) >= 1;
	maxtab = maxtab(maxtab(:, 1) > 2, :); % leaving out the first point
	mintab = mintab(mintab(:, 1) > maxtab(1, 1), :); % retainig the troughs only after the first peak
	switch peak_detect_appr
	case 'no-checks'
		q_point = mintab(1, :);
		t_point = maxtab(maxtab(:, 1) > 70, :);
	case 'mean-whole-signal'
		hold_mintab = find(mintab(:, 2) < mean(individual_chunks));
		q_point = mintab(hold_mintab(1), :);
		hold_maxtab = find(maxtab(:, 2) > mean(individual_chunks));
		t_point = maxtab(hold_maxtab(end), :);
	case 'mean-first-last'
		hold_mintab = find(mintab(:, 2) < mean([individual_chunks(1), individual_chunks(end)]));
		q_point = mintab(hold_mintab(1), :);
		hold_maxtab = find(maxtab(:, 2) > mean([individual_chunks(1), individual_chunks(end)]));
		t_point = maxtab(hold_maxtab(end), :);
	otherwise, error('Invalid peak detection technique');
	end	

	if size(q_point, 1) == 1 & size(t_point, 1) == 1;
		h1=plot(q_point(1, 1), q_point(1, 2), '*', 'color', set_colors, 'MarkerSize', 10);
		hAnnotation = get(h1, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');

		h2=plot(t_point(1, 1), t_point(1, 2), 's', 'color', set_colors, 'MarkerSize', 10);
		hAnnotation = get(h2, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
	else
		disp(sprintf('Missing either q or t point'));
		q_point = [0, 0]; t_point = [0, 0];
	end
	if visible_flag, pause(0.5); end
else
	disp(sprintf('No peaks detected'));
	q_point = [0, 0]; t_point = [0, 0];
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

