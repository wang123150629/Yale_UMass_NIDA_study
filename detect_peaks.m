function[subject_profile] = detect_peaks(subject_profile, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag)

subject_id =  subject_profile.subject_id;

for v = 1:subject_profile.nEvents
	if ~isfield(subject_profile.events{v}, sprintf('peaks_%s%d', slide_or_chunk, time_window))
		mat_path = detect_peaks_within_events(subject_profile, slide_or_chunk, time_window,...
						peak_detect_appr, pqrst_flag, v);
		subject_profile.events{v} = setfield(subject_profile.events{v},...
					sprintf('peaks_%s%d', slide_or_chunk, time_window), mat_path);
		plot_distance_bw_peaks(subject_profile, v, slide_or_chunk,...
			time_window, peak_detect_appr, pqrst_flag);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mat_path] = detect_peaks_within_events(subject_profile, slide_or_chunk, time_window,...
						peak_detect_appr, pqrst_flag, event)

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');

subject_id = subject_profile.subject_id;
exp_sessions = subject_profile.events{event}.exp_sessions;
dosage_levels = subject_profile.events{event}.dosage_levels;
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
behav_mat_columns = subject_profile.columns.behav;
infusion_indices = find(behav_mat(:, behav_mat_columns.infusion) == 1);
click_indices = find(behav_mat(:, behav_mat_columns.click) == 1);
window_data = load(getfield(subject_profile.events{event}, sprintf('%s%d_win_mat_path', slide_or_chunk, time_window)));
switch slide_or_chunk
case 'chunk', sl_ch_str = 'minute window';
case 'slide', sl_ch_str = 'sec sliding window';
end
if pqrst_flag
	window_data = window_data.pqrst_mat;
	pqrst_rr_peaks_str = 'pqrst';
else
	window_data = window_data.rr_mat;
	pqrst_rr_peaks_str = 'rr';
end

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
start_hh_col = nInterpolatedFeatures + 2;
start_mm_col = nInterpolatedFeatures + 3;
end_hh_col = nInterpolatedFeatures + 4;
end_mm_col = nInterpolatedFeatures + 5;
nSamples_col = nInterpolatedFeatures + 6;
dosage_col = nInterpolatedFeatures + 7;
exp_session_col = nInterpolatedFeatures + 8;

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
title(sprintf('%s, %s, %d %s', get_project_settings('strrep_subj_id', subject_id), subject_profile.events{1, event}.label,...
									time_window, sl_ch_str));
hold on; grid on;
xlim([0, get_project_settings('nInterpolatedFeatures')]);
ylim(subject_profile.ylim);
ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');

info_per_chunk = struct();
info_per_chunk.p_point = [];
info_per_chunk.q_point = [];
info_per_chunk.r_point = [];
info_per_chunk.s_point = [];
info_per_chunk.t_point = [];
info_per_chunk.infusion_presence = [];
info_per_chunk.click_presence = [];

for e = 1:length(exp_sessions)
	individual_chunks = window_data(window_data(:, exp_session_col) == exp_sessions(e), :);
	colors = jet(size(individual_chunks, 1));
	for d = 1:length(dosage_levels)
	for s = 1:size(individual_chunks, 1)
	if any(individual_chunks(s, dosage_col) == dosage_levels(d))

		[p_point, q_point, r_point, s_point, t_point] = find_peaks(peak_detect_appr, individual_chunks(s, ecg_col),...
						individual_chunks(s, nSamples_col), colors(s, :));
		if ~isempty(find(q_point)) % Mere existence of q_point signifies that all five points exist as per strict-3-2
			plot(individual_chunks(s, ecg_col), 'color', colors(s, :));
		end
		
		infusion_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
				behav_mat(infusion_indices, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm),...
				sprintf('%s%d', slide_or_chunk, time_window));
		click_presence = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
				behav_mat(click_indices, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm),...
				sprintf('%s%d', slide_or_chunk, time_window));

		info_per_chunk.p_point = [info_per_chunk.p_point; p_point];
		info_per_chunk.q_point = [info_per_chunk.q_point; q_point];
		info_per_chunk.r_point = [info_per_chunk.r_point; r_point];
		info_per_chunk.s_point = [info_per_chunk.s_point; s_point];
		info_per_chunk.t_point = [info_per_chunk.t_point; t_point];
		info_per_chunk.infusion_presence = [info_per_chunk.infusion_presence; infusion_presence];
		info_per_chunk.click_presence = [info_per_chunk.click_presence; click_presence];
	end
	end
	end
end

file_name = sprintf('%s/%s/%s_%s%d_peak%d_detection', get_project_settings('plots'), subject_id,...
		subject_profile.events{event}.file_name, slide_or_chunk, time_window, peak_detect_appr);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

mat_path = fullfile(result_dir, subject_id, sprintf('%s_%s_peaks_%s%d', subject_profile.events{event}.file_name,...
				pqrst_rr_peaks_str, slide_or_chunk, time_window));
save(mat_path, '-struct', 'info_per_chunk');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[p_point, q_point, r_point, s_point, t_point] = find_peaks(peak_detect_appr, individual_chunks, nSamples, set_colors)

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
		otherwise, error('Invalid peak detection technique');
		end

		if size(q_point, 1) == 1 & size(t_point, 1) == 1;
			plot(p_point(1, 1), p_point(1, 2), 'r*', 'MarkerSize', 10);
			plot(q_point(1, 1), q_point(1, 2), 'g*', 'MarkerSize', 10);
			plot(r_point(1, 1), r_point(1, 2), 'b*', 'MarkerSize', 10);
			plot(s_point(1, 1), s_point(1, 2), 'k*', 'MarkerSize', 10);
			plot(t_point(1, 1), t_point(1, 2), 'm*', 'MarkerSize', 10);
		else
			disp(sprintf('Missing either one of the five points due to the strict 3-2 approach'));
			q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
		end
	else
		disp(sprintf('Missing peaks when checking for maxtab and mintab'));
		q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
	end
else
	disp(sprintf('No peaks detected'));
	q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[event_presence_absence] = detect_event(chunk_start_end, behav_event_data, win_plus_time)

start_hh = chunk_start_end(1);
start_mm = chunk_start_end(2);
end_hh = chunk_start_end(3);
end_mm = chunk_start_end(4);
switch win_plus_time
case 'chunk5'
	event_presence_absence = sum((behav_event_data(:, 1) > start_hh |...
				      behav_event_data(:, 1) == start_hh & behav_event_data(:, 2) >= start_mm) &...
	    		   	     (behav_event_data(:, 1) < end_hh |...
				      behav_event_data(:, 1) == end_hh & behav_event_data(:, 2) < end_mm) );
case 'slide30'
	event_presence_absence = sum(behav_event_data(:, 1) == start_hh & behav_event_data(:, 2) == start_mm &...
	    		   	     behav_event_data(:, 1) == end_hh & behav_event_data(:, 2) == end_mm);
case 'slide180'
	event_presence_absence = sum((behav_event_data(:, 1) > start_hh |...
				      behav_event_data(:, 1) == start_hh & behav_event_data(:, 2) >= start_mm) &...
	    		   	     (behav_event_data(:, 1) < end_hh |...
				      behav_event_data(:, 1) == end_hh & behav_event_data(:, 2) < end_mm) );
otherwise, error('Invlid windowing technique!');
end

