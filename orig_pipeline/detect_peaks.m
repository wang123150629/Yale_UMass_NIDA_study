function[subject_profile] = detect_peaks(subject_profile, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag)

subject_id =  subject_profile.subject_id;

for v = 1:subject_profile.nEvents
	% if ~isfield(subject_profile.events{v}, sprintf('peaks_%s%d', slide_or_chunk, time_window))
		mat_path = detect_peaks_within_events(subject_profile, slide_or_chunk, time_window,...
						peak_detect_appr, pqrst_flag, v);
		subject_profile.events{v} = setfield(subject_profile.events{v},...
					sprintf('peaks_%s%d', slide_or_chunk, time_window), mat_path);
		plot_distance_bw_peaks(subject_profile, v, slide_or_chunk,...
			time_window, peak_detect_appr, pqrst_flag);
	% end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mat_path] = detect_peaks_within_events(subject_profile, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag, event)

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
peakdet_thresholds = get_project_settings('peak_thresholds');

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

info_per_chunk = struct();
info_per_chunk.p_point = [];
info_per_chunk.q_point = [];
info_per_chunk.r_point = [];
info_per_chunk.s_point = [];
info_per_chunk.t_point = [];
info_per_chunk.infusion_presence = [];
info_per_chunk.click_presence = [];
info_per_chunk.best_peak_thres = [];

for e = 1:length(exp_sessions)
	for d = 1:length(dosage_levels)
		target_rows = window_data(:, exp_session_col) == exp_sessions(e) & window_data(:, dosage_col) == dosage_levels(d);
		if sum(target_rows) > 0
			individual_chunks = window_data(target_rows, :);
			nIndChunks = size(individual_chunks, 1);

			infusion_presence = NaN(nIndChunks, 1);
			click_presence = NaN(nIndChunks, 1);
			for s = 1:size(individual_chunks, 1)
				infusion_presence(s) = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
						behav_mat(infusion_indices, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm),...
						sprintf('%s%d', slide_or_chunk, time_window));
				click_presence(s) = detect_event(individual_chunks(s, start_hh_col:end_mm_col),...
						behav_mat(click_indices, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm),...
						sprintf('%s%d', slide_or_chunk, time_window));
			end
			info_per_chunk.infusion_presence = [info_per_chunk.infusion_presence; infusion_presence];
			info_per_chunk.click_presence = [info_per_chunk.click_presence; click_presence];

			how_many_peaks = 0;
			best_peak_threshold = NaN;
			peaks_locked = zeros(nIndChunks, 10);
			for p = 1:length(peakdet_thresholds)
				p_point = NaN(nIndChunks, 2); q_point = NaN(nIndChunks, 2); r_point = NaN(nIndChunks, 2);
				s_point = NaN(nIndChunks, 2); t_point = NaN(nIndChunks, 2); 
				for s = 1:size(individual_chunks, 1)
					[p_point(s, :), q_point(s, :), r_point(s, :), s_point(s, :), t_point(s, :)] =...
						find_peaks(peak_detect_appr, individual_chunks(s, ecg_col), peakdet_thresholds(p));
				end
				if sum(p_point(:, 1) > 0) > how_many_peaks
					assert(size(p_point, 2) == 2);
					peaks_locked = [p_point, q_point, r_point, s_point, t_point];
					how_many_peaks = sum(p_point(:, 1) > 0);
					best_peak_threshold = peakdet_thresholds(p);
				end
			end

			info_per_chunk.p_point = [info_per_chunk.p_point; peaks_locked(:, 1:2)];
			info_per_chunk.q_point = [info_per_chunk.q_point; peaks_locked(:, 3:4)];
			info_per_chunk.r_point = [info_per_chunk.r_point; peaks_locked(:, 5:6)];
			info_per_chunk.s_point = [info_per_chunk.s_point; peaks_locked(:, 7:8)];
			info_per_chunk.t_point = [info_per_chunk.t_point; peaks_locked(:, 9:10)];
			info_per_chunk.best_peak_thres = [info_per_chunk.best_peak_thres; best_peak_threshold];
			fprintf('Exp: %d, Dosage: %d, thres=%0.4f\n', exp_sessions(e), dosage_levels(d), best_peak_threshold);
		end
	end
end

how_many_samples_had_peaks = find(info_per_chunk.p_point(:, 1) > 0);
colors = jet(length(how_many_samples_had_peaks));

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
title(sprintf('%s, %s, %d %s', get_project_settings('strrep_subj_id', subject_id), subject_profile.events{1, event}.label,...
									time_window, sl_ch_str));
xlim([0, get_project_settings('nInterpolatedFeatures')]);
ylim(subject_profile.ylim);
ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
set(gca, 'ColorOrder', colors, 'NextPlot', 'replacechildren'); % Change to new colors.
plot(ecg_col, window_data(how_many_samples_had_peaks, ecg_col));
hold on; grid on;
plot(info_per_chunk.p_point(how_many_samples_had_peaks, 1), info_per_chunk.p_point(how_many_samples_had_peaks, 2), 'r*');
plot(info_per_chunk.q_point(how_many_samples_had_peaks, 1), info_per_chunk.q_point(how_many_samples_had_peaks, 2), 'g*');
plot(info_per_chunk.r_point(how_many_samples_had_peaks, 1), info_per_chunk.r_point(how_many_samples_had_peaks, 2), 'b*');
plot(info_per_chunk.s_point(how_many_samples_had_peaks, 1), info_per_chunk.s_point(how_many_samples_had_peaks, 2), 'k*');
plot(info_per_chunk.t_point(how_many_samples_had_peaks, 1), info_per_chunk.t_point(how_many_samples_had_peaks, 2), 'm*');
file_name = sprintf('%s/%s/%s_%s%d_peak%d_detection', get_project_settings('plots'), subject_id,...
		subject_profile.events{event}.file_name, slide_or_chunk, time_window, peak_detect_appr);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

mat_path = fullfile(result_dir, subject_id, sprintf('%s_%s_peaks_%s%d', subject_profile.events{event}.file_name,...
				pqrst_rr_peaks_str, slide_or_chunk, time_window));
save(mat_path, '-struct', 'info_per_chunk');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[p_point, q_point, r_point, s_point, t_point] = find_peaks(peak_detect_appr, individual_chunks, peak_thres)

q_point = [0, 0]; t_point = [0, 0]; p_point = [0, 0]; r_point = [0, 0]; s_point = [0, 0];

[maxtab, mintab] = peakdet(individual_chunks, peak_thres);

if size(maxtab, 1) >= 1 & size(mintab, 1) >= 1
	if maxtab(1, 1) == 1
		maxtab = maxtab(maxtab(:, 1) > 2, :); % leaving out the first point
	end
	if ~isempty(maxtab)
		mintab = mintab(mintab(:, 1) > maxtab(1, 1), :); % retaining the troughs only after the first peak
	end
	if ~isempty(maxtab) & ~isempty(mintab) % only when both exist
		switch get_project_settings('peak_det', peak_detect_appr)
		case 'strict-3-2'
			if size(maxtab, 1) == 3 & size(mintab, 1) == 2 &...
			   sign(mintab(1, 1) - maxtab(1, 1)) &...
			   sign(maxtab(2, 1) - mintab(1, 1)) &...
			   sign(mintab(2, 1) - maxtab(2, 1)) &...
			   sign(maxtab(3, 1) - mintab(2, 1)) &...
			   (maxtab(3, 1) - maxtab(2, 1) >= 20) &...
			   (maxtab(3, 1) >= 65)
				p_point = maxtab(1, :);
				q_point = mintab(1, :);
				r_point = maxtab(2, :);
				s_point = mintab(2, :);
				t_point = maxtab(3, :);
			end
		case 'strict-3-2-old'
			if size(maxtab, 1) == 3 & size(mintab, 1) == 2
				p_point = maxtab(1, :);
				q_point = mintab(1, :);
				r_point = maxtab(2, :);
				s_point = mintab(2, :);
				t_point = maxtab(3, :);
			end
		otherwise, error('Invalid peak detection technique');
		end
	end
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

%{
a = mean(info_per_chunk.p_point(info_per_chunk.p_point(:, 1) > 0, :));
b = mean(info_per_chunk.q_point(info_per_chunk.q_point(:, 1) > 0, :));
c = mean(info_per_chunk.r_point(info_per_chunk.r_point(:, 1) > 0, :));
d = mean(info_per_chunk.s_point(info_per_chunk.s_point(:, 1) > 0, :));
e = mean(info_per_chunk.t_point(info_per_chunk.t_point(:, 1) > 0, :));
fprintf('%0.4f, %0.4f, %0.4f, %0.4f, %0.4f\n', a(1), b(1), c(1), d(1), e(1));
%}

%{
	how_many_samples_had_peaks = find(info_per_chunk.p_point(:, 1) > 0);
	how_many_samples_had_peaks = how_many_samples_had_peaks(how_many_samples_had_peaks > 1000);
	for h = 1:length(how_many_samples_had_peaks)
		font_size = get_project_settings('font_size');
		le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
		xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
		figure('visible', 'off')
		set(gcf, 'PaperPosition', [0 0 6 6]);
		set(gcf, 'PaperSize', [6 6]);
		plot(ecg_col, window_data(how_many_samples_had_peaks(h), ecg_col), 'g-', 'LineWidth', 2); hold on;
	text(info_per_chunk.p_point(how_many_samples_had_peaks(h), 1), info_per_chunk.p_point(how_many_samples_had_peaks(h), 2), 'P',...
'FontSize', 30, 'FontWeight', 'b', 'FontName', 'Times');
	text(info_per_chunk.q_point(how_many_samples_had_peaks(h), 1), info_per_chunk.q_point(how_many_samples_had_peaks(h), 2), 'Q',...
'FontSize', 30, 'FontWeight', 'b', 'FontName', 'Times');
	text(info_per_chunk.r_point(how_many_samples_had_peaks(h), 1), info_per_chunk.r_point(how_many_samples_had_peaks(h), 2), 'R',...
'FontSize', 30, 'FontWeight', 'b', 'FontName', 'Times');
	text(info_per_chunk.s_point(how_many_samples_had_peaks(h), 1), info_per_chunk.s_point(how_many_samples_had_peaks(h), 2), 'S',...
'FontSize', 30, 'FontWeight', 'b', 'FontName', 'Times');
	text(info_per_chunk.t_point(how_many_samples_had_peaks(h), 1), info_per_chunk.t_point(how_many_samples_had_peaks(h), 2), 'T',...
'FontSize', 30, 'FontWeight', 'b', 'FontName', 'Times');
		x_tick = get(gca, 'XtickLabel'); % ylim([0, 5]);
		set(gca, 'XtickLabel', str2num(x_tick) .* 4, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
		xlabel('Interpolated(400 milliseconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		ylabel('std. millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		file_name = sprintf('/home/anataraj/Desktop/peak/peaks%d', h);
		saveas(gcf, file_name, 'pdf')
	end
	keyboard
%}

