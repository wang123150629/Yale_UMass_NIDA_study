function[preprocessed_data] = preprocess_ecg_data(subject_id, subject_session, subject_threshold)

data_dir = get_project_settings('data');
plot_dir = get_project_settings('plots');
if ~exist(fullfile(plot_dir, subject_id))
	mkdir(fullfile(plot_dir, subject_id));
end
result_dir = get_project_settings('results');
if ~exist(fullfile(result_dir, subject_id))
	mkdir(fullfile(result_dir, subject_id));
end
summ_mat_time_res = get_project_settings('summ_mat_time_res');
data_mat_columns = get_project_settings('data_mat_columns');
exp_sessions = get_project_settings('exp_sessions');

% Loading the raw ECG data
% The raw ECG data is sampled every 4 milliseconds so for every 250 (250 x 4 = 1000 = 1 second) samples we will have an entry in the summary table. Now the summary table has entries for sec1.440 i.e. sec1.440 to sec2.436 are summarized into this entry.
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);
% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_session,...
			sprintf('%s_summary_clean.csv', subject_session)), 1, 0);
% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
% Fetching the absolute and event indices
index_maps = find_start_end_time(summary_mat, behav_mat, summ_mat_time_res);

plot_time_series(data_mat_columns, summary_mat, behav_mat, index_maps, subject_id);

assert(size(subject_threshold, 1) == length(exp_sessions));
preprocessed_data = cell(1, length(exp_sessions));
for e = 1:length(exp_sessions)
	preprocessed_data{1, e} = preprocess_by_session(subject_id, subject_session, exp_sessions(e),...
				subject_threshold(e, :), ecg_mat, summary_mat, behav_mat, index_maps);
end
save(fullfile(result_dir, subject_id, sprintf('preprocessed_data')), 'preprocessed_data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[session_data] = preprocess_by_session(subject_id, subject_session, experiment_session,...
		       	 subject_threshold, ecg_mat, summary_mat, behav_mat, index_maps)

image_format = get_project_settings('image_format');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
dosage_levels = get_project_settings('dosage_levels');
assert(length(subject_threshold) == length(dosage_levels));
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');

session_data = struct();
session_data.interpolated_ecg = [];
session_data.dosage_labels = [];
session_data.hold_start_end_indices = [];
session_data.x_size = [];
session_data.x_time = cell(1, length(dosage_levels));

for d = 1:length(dosage_levels)
	% For the d mg infusion ONLY in the first session, fetch the associated indices from the absolute time axis.
	% For instance this fetches 11100:60:12660 = 27 time points
	sess_start_end = find(behav_mat(:, 5) == experiment_session);
	dosg_start_end = find(behav_mat(:, 6) == dosage_levels(d));
	dosg_sess_start_end = intersect(dosg_start_end, sess_start_end);
	if ~isempty(dosg_sess_start_end)
		dos_interpolated_ecg = [];
		disp(sprintf('dosage=%d', dosage_levels(d)));
		disp(sprintf('Behav: %d:%d -- %d:%d', behav_mat(dosg_sess_start_end(1), 3),...
			behav_mat(dosg_sess_start_end(1), 4),...
			behav_mat(dosg_sess_start_end(end), 3), behav_mat(dosg_sess_start_end(end), 4)));
		behav_start_end_times = intersect(index_maps.behav(dosg_start_end), index_maps.behav(sess_start_end));

		% Now this subtracts 11100 - 8154 which gives 2946. This is telling us that the 2946th time point in the
		% summary file corresponds to the start of the d mg, first session.
		summ_start_time = behav_start_end_times(1) - (index_maps.summary(1)-1);
		% Similarly for the end time point it is 12720 - 8155 = 4565th time point
		summ_end_time = behav_start_end_times(end)+60 - index_maps.summary(1);
		disp(sprintf('Summ: %d:%d:%0.3f -- %d:%d:%0.3f', summary_mat(summ_start_time, 4),...
			summary_mat(summ_start_time, 5), summary_mat(summ_start_time, 6),...
			summary_mat(summ_end_time, 4), summary_mat(summ_end_time, 5), summary_mat(summ_end_time, 6)));
		% Checking if the length of the extracted segments based on the time points is the same as the
		% start_end time vector. The key is to understand that the summary and absolute time axis are in
		% the same resolution i.e. 60, one sample per second
		assert(length(summ_start_time:60:summ_end_time) == length(behav_start_end_times));

		% Now we need to jump from 60 second resolution to 250 samples per second resolution in the raw ECG data
		raw_start_time = (summ_start_time - 1) * 250 + 1;
		raw_end_time = (summ_end_time - 1) * 250 + 1;
		disp(sprintf('Raw ECG: %d:%d:%0.3f -- %d:%d:%0.3f', ecg_mat(raw_start_time, 4),...
			ecg_mat(raw_start_time, 5), ecg_mat(raw_start_time, 6),...
			ecg_mat(raw_end_time, 4), ecg_mat(raw_end_time, 5), ecg_mat(raw_end_time, 6)));

		% converting the bioharness numbers into millivolts
		x = ecg_mat(raw_start_time:raw_end_time, 7) .* 0.001220703125;
		session_data.x_size(d) = length(x);
		x_time = ecg_mat(raw_start_time:raw_end_time, 4:6);
		session_data.x_time{1, d} = x_time;

		%{
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot 1: Raw ECG for baselines, 8mg, etc
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
		plot(x, 'b-');
		xlabel('Time(4ms resolution)'); ylabel('millivolts');
		title(sprintf('%s, raw ECG', title_str)); ylim([0, 5]);
		file_name = sprintf('%s/subj_%s_dos_%d_raw_chunk', plot_dir, subject_id, d);
		savesamesize(gcf, 'file', file_name, 'format', image_format);
		%}

		[rr, rs] = rrextract(x, 250, subject_threshold(d));
		rr_start_end = [rr(1:end-1); rr(2:end)-1]';
		hold_start_end_indices = [];
		valid_rr_intervals = [];
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot 2: Raw ECG broken into RR chunks; variable length
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
		for s = 1:size(rr_start_end, 1)
			if (rr_start_end(s, 2) - rr_start_end(s, 1)) > cut_off_heart_rate(1) &...
			   (rr_start_end(s, 2) - rr_start_end(s, 1)) <= cut_off_heart_rate(2)
				% plot(x(rr_start_end(s, 1):rr_start_end(s, 2)), 'r-'); hold on;

				% Interplotaing the RR chunks
				x_length = length(x(rr_start_end(s, 1):rr_start_end(s, 2)));
				xi = linspace(1, x_length, nInterpolatedFeatures);
				interpol_data = interp1(1:x_length, x(rr_start_end(s, 1):rr_start_end(s, 2)),...
						xi, 'pchip');
				if max(interpol_data) <= 5 & min(interpol_data) >= 0
					dos_interpolated_ecg = [dos_interpolated_ecg; interpol_data];
					hold_start_end_indices = [hold_start_end_indices; rr_start_end(s, :)];
					% valid_rr_intervals = [valid_rr_intervals; rr_start_end(s, 2) -...
					%			rr_start_end(s, 1)];
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
	end
end

session_data.dosage_levels = unique(session_data.dosage_labels);

