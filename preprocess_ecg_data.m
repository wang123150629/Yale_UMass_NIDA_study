function[subject_profile] = preprocess_ecg_data(subject_profile)

data_dir = get_project_settings('data');
plot_dir = get_project_settings('plots');
subject_id =  subject_profile.subject_id;
if ~exist(fullfile(plot_dir, subject_id))
	mkdir(fullfile(plot_dir, subject_id));
end
result_dir = get_project_settings('results');
if ~exist(fullfile(result_dir, subject_id))
	mkdir(fullfile(result_dir, subject_id));
end

for v = 1:subject_profile.nEvents
	if ~isfield(subject_profile.events{v}, 'preprocessed_mat_path')
		switch subject_profile.events{v}.label
		case 'cocaine'
			mat_path = preprocess_cocaine_day_data(subject_profile, v);
		otherwise
			mat_path = preprocess_event_data(subject_profile, v);
		end
		subject_profile.events{v}.preprocessed_mat_path = mat_path;
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mat_path] = preprocess_cocaine_day_data(subject_profile, event)

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
summ_mat_time_res = get_project_settings('summ_mat_time_res');

subject_id =  subject_profile.subject_id;
summ_mat_columns = subject_profile.columns.summ;
behav_mat_columns = subject_profile.columns.behav;
raw_ecg_mat_columns = subject_profile.columns.raw_ecg;
subject_timestamp = subject_profile.events{event}.timestamp;
subject_sensor = subject_profile.events{event}.sensor;

% Loading the raw ECG data
% The raw ECG data is sampled every 4 milliseconds so for every 250 (250 x 4 = 1000 = 1 second) samples we will have an entry in the summary table. Now the summary table has entries for sec1.440 i.e. sec1.440 to sec2.436 are summarized into this entry.
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
			sprintf('%s_ECG_clean.csv', subject_timestamp)), 1, 0);
% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
			sprintf('%s_summary_clean.csv', subject_timestamp)), 1, 0);
% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
% Fetching the absolute and event indices
index_maps = find_start_end_time(subject_profile, summary_mat, behav_mat, summ_mat_time_res);

plot_time_series(summ_mat_columns, summary_mat, behav_mat, index_maps, subject_profile, event);

preprocessed_data = cell(1, length(subject_profile.events{event}.exp_sessions));
for e = 1:length(subject_profile.events{event}.exp_sessions)
	preprocessed_data{1, e} = preprocess_by_session(subject_profile, ecg_mat, summary_mat, behav_mat, index_maps, event, e);
end
mat_path = fullfile(result_dir, subject_id, sprintf('%s_preprocessed_data', subject_profile.events{event}.file_name));
save(mat_path, 'preprocessed_data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[session_data] = preprocess_by_session(subject_profile, ecg_mat, summary_mat, behav_mat, index_maps, event, exp_sess_no)

image_format = get_project_settings('image_format');
plot_dir = get_project_settings('plots');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
summ_mat_time_res = get_project_settings('summ_mat_time_res');
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');

subject_id =  subject_profile.subject_id;
subject_threshold = subject_profile.events{event}.rr_thresholds;
experiment_session = subject_profile.events{event}.exp_sessions(exp_sess_no);
dosage_levels = subject_profile.events{event}.dosage_levels;
behav_mat_columns = subject_profile.columns.behav;
summ_mat_columns = subject_profile.columns.summ;
raw_ecg_mat_columns = subject_profile.columns.raw_ecg;

session_data = struct();
session_data.interpolated_ecg = [];
session_data.dosage_labels = [];
session_data.hold_start_end_indices = [];
session_data.x_size = [];
session_data.x_time = cell(1, length(dosage_levels));
session_data.valid_rr_intervals = [];

for d = 1:length(dosage_levels)
	% For the d mg infusion ONLY in the first session, fetch the associated indices from the absolute time axis.
	% For instance this fetches 11100:60:12660 = 27 time points
	sess_start_end = find(behav_mat(:, behav_mat_columns.session) == experiment_session);
	dosg_start_end = find(behav_mat(:, behav_mat_columns.dosage) == dosage_levels(d));
	dosg_sess_start_end = intersect(dosg_start_end, sess_start_end);
	if ~isempty(dosg_sess_start_end)
		dos_interpolated_ecg = [];
		disp(sprintf('dosage=%d', dosage_levels(d)));
		disp(sprintf('Behav: %d:%d -- %d:%d',...
			behav_mat(dosg_sess_start_end(1), behav_mat_columns.actual_hh),...
			behav_mat(dosg_sess_start_end(1), behav_mat_columns.actual_mm),...
			behav_mat(dosg_sess_start_end(end), behav_mat_columns.actual_hh),...
			behav_mat(dosg_sess_start_end(end), behav_mat_columns.actual_mm)));
		behav_start_end_times = intersect(index_maps.behav(dosg_start_end), index_maps.behav(sess_start_end));

		% Now this subtracts 11100 - 8154 which gives 2946. This is telling us that the 2946th time point in the
		% summary file corresponds to the start of the d mg, first session.
		summ_start_time = behav_start_end_times(1) - (index_maps.summary(1)-1);
		% Similarly for the end time point it is 12720 - 8155 = 4565th time point
		summ_end_time = behav_start_end_times(end)+summ_mat_time_res - index_maps.summary(1);
		disp(sprintf('Summ: %d:%d:%0.3f -- %d:%d:%0.3f',...
			summary_mat(summ_start_time, summ_mat_columns.actual_hh),...
			summary_mat(summ_start_time, summ_mat_columns.actual_mm),...
			summary_mat(summ_start_time, summ_mat_columns.actual_ss),...
			summary_mat(summ_end_time, summ_mat_columns.actual_hh),...
			summary_mat(summ_end_time, summ_mat_columns.actual_mm),...
			summary_mat(summ_end_time, summ_mat_columns.actual_ss)));
		% Checking if the length of the extracted segments based on the time points is the same as the
		% start_end time vector. The key is to understand that the summary and absolute time axis are in
		% the same resolution i.e. 60, one sample per second
		assert(length(summ_start_time:summ_mat_time_res:summ_end_time) == length(behav_start_end_times));

		% Now we need to jump from 60 second resolution to 250 samples per second resolution in the raw ECG data
		raw_start_time = (summ_start_time - 1) * raw_ecg_mat_time_res + 1;
		raw_end_time = (summ_end_time - 1) * raw_ecg_mat_time_res + 1;
		disp(sprintf('Raw ECG: %d:%d:%0.3f -- %d:%d:%0.3f',...
			ecg_mat(raw_start_time, raw_ecg_mat_columns.actual_hh),...
			ecg_mat(raw_start_time, raw_ecg_mat_columns.actual_mm),...
			ecg_mat(raw_start_time, raw_ecg_mat_columns.actual_ss),...
			ecg_mat(raw_end_time, raw_ecg_mat_columns.actual_hh),...
			ecg_mat(raw_end_time, raw_ecg_mat_columns.actual_mm),...
			ecg_mat(raw_end_time, raw_ecg_mat_columns.actual_ss)));

		% converting the bioharness numbers into millivolts
		x = ecg_mat(raw_start_time:raw_end_time, raw_ecg_mat_columns.ecg) .* 0.001220703125;
		session_data.x_size(d) = length(x);
		x_time = ecg_mat(raw_start_time:raw_end_time, raw_ecg_mat_columns.actual_hh:raw_ecg_mat_columns.actual_ss);
		session_data.x_time{1, d} = x_time;

		%{
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot 1: Raw ECG for baselines, 8mg, etc
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		figure(); set(gcf, 'Position', get_project_settings('figure_size'));
		plot(x, 'b-');
		xlabel('Time(4ms resolution)'); ylabel('millivolts');
		title(sprintf('%s, raw ECG', title_str)); ylim([0, 5]);
		file_name = sprintf('%s/subj_%s_dos_%d_raw_chunk', plot_dir, subject_id, d);
		savesamesize(gcf, 'file', file_name, 'format', image_format);
		%}

		[rr, rs] = rrextract(x, raw_ecg_mat_time_res, subject_threshold);
		rr_start_end = [rr(1:end-1); rr(2:end)-1]';
		hold_start_end_indices = [];
		valid_rr_intervals = [];
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot 2: Raw ECG broken into RR chunks; variable length
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% figure(); set(gcf, 'Position', get_project_settings('figure_size'));
		for s = 1:size(rr_start_end, 1)
			if (rr_start_end(s, 2) - rr_start_end(s, 1)) > cut_off_heart_rate(1) &...
			   (rr_start_end(s, 2) - rr_start_end(s, 1)) <= cut_off_heart_rate(2)
				% plot(x(rr_start_end(s, 1):rr_start_end(s, 2)), 'r-'); hold on;

				% Interplotaing the RR chunks
				x_length = length(x(rr_start_end(s, 1):rr_start_end(s, 2)));
				xi = linspace(1, x_length, nInterpolatedFeatures);
				interpol_data = interp1(1:x_length, x(rr_start_end(s, 1):rr_start_end(s, 2)), xi, 'pchip');
				if max(interpol_data) <= 5 & min(interpol_data) >= 0
					dos_interpolated_ecg = [dos_interpolated_ecg; interpol_data];
					hold_start_end_indices = [hold_start_end_indices; rr_start_end(s, :)];
					valid_rr_intervals = [valid_rr_intervals; x_length];
				else
					disp(sprintf('Interpolated data is out of bounds!')); keyboard
				end
			end
		end
		%{
		plot(repmat(cut_off_heart_rate(1), 1, 6), 0:5, 'k*');
		plot(repmat(cut_off_heart_rate(2), 1, 6), 0:5, 'k*');
		xlabel('Time(milliseconds)'); ylabel('millivolts');
		title(sprintf('%s, raw ECG b/w RR', title_str)); ylim([0, 5]);
		set(gca, 'XTickLabel', str2num(get(gca, 'XTickLabel')) * 4);
		file_name = sprintf('%s/subj_%s_dos_%d_raw_rr', plot_dir, subject_id, d);
		savesamesize(gcf, 'file', file_name, 'format', image_format);
		%}
		session_data.interpolated_ecg = [session_data.interpolated_ecg;...
						dos_interpolated_ecg];
		session_data.dosage_labels = [session_data.dosage_labels;...
						repmat(dosage_levels(d), size(dos_interpolated_ecg, 1), 1)];
		session_data.hold_start_end_indices = [session_data.hold_start_end_indices;...
						hold_start_end_indices];
		session_data.valid_rr_intervals = [session_data.valid_rr_intervals;...
						valid_rr_intervals];
	end
end

