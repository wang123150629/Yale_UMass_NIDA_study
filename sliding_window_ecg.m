function[] = sliding_window_ecg(preprocessed_data, subject_id)

result_dir = get_project_settings('results');
exp_sessions = get_project_settings('exp_sessions');
how_many_sec_per_win = get_project_settings('how_many_sec_per_win');

sliding_ksec_win = cell(1, length(exp_sessions));
for e = 1:length(exp_sessions)
	sliding_ksec_win{1, e} = slide_win_and_build_dataset(preprocessed_data{1, e}, subject_id, exp_sessions(e));
end
save(fullfile(result_dir, subject_id, sprintf('sliding_%dsec_win', how_many_sec_per_win)), 'sliding_ksec_win');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[sliding_ksec_win] = slide_win_and_build_dataset(preprocessed_data, subject_id, experiment_session)

plot_dir = get_project_settings('plots');
result_dir = get_project_settings('results');
image_format = get_project_settings('image_format');
dosage_levels = get_project_settings('dosage_levels');
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
how_many_sec_per_win = get_project_settings('how_many_sec_per_win');
% This data comes from pre-processing.m We do not rely on project settings here since some sessions contain only some dosage levels 
this_sess_dosage_levels = preprocessed_data.dosage_levels;

sliding_ksec_win = struct();
sliding_ksec_win.rr = [];
sliding_ksec_win.pqrst = [];

for d = 1:length(this_sess_dosage_levels)
	target_dosage_idx = preprocessed_data.dosage_labels == this_sess_dosage_levels(d); % pick out rows
	interpolated_ecg = preprocessed_data.interpolated_ecg(target_dosage_idx, :); % pick out corresponding features
	hold_start_end_indices = preprocessed_data.hold_start_end_indices(target_dosage_idx, :); % start end indices
	rr_intervals = preprocessed_data.valid_rr_intervals(target_dosage_idx, :); % start end indices
	assert(all(hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) >= cut_off_heart_rate(1) &...
	           hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) <= cut_off_heart_rate(2)));
	x_size = preprocessed_data.x_size(this_sess_dosage_levels(d) == dosage_levels);
	x_time = preprocessed_data.x_time{this_sess_dosage_levels(d) == dosage_levels};

	% This is taking the entire, say baseline, session and breaking it into k second windows. It is important to note that
	% each window is of length 7500 (250 x 30 seconds) and the window slides by 250 i.e. one full second
	samples_clusters = [1:250:(x_size-(250 * how_many_sec_per_win)+1); (250 * how_many_sec_per_win):250:x_size]';
	assert(length(unique(samples_clusters(:, 2) - samples_clusters(:, 1))) == 1);

	for s = 1:size(samples_clusters, 1)
		% Finding samples that lie within this k sec window. This could result in say samples 2, 3, 4, 5
		target_idx = intersect(find(hold_start_end_indices(:, 1) >= samples_clusters(s, 1)),...
			  	       find(hold_start_end_indices(:, 2) <= samples_clusters(s, 2)));
		% Picking out those four samples i.e. 2, 3, 4, 5
		interpolated_ecg_within_win = interpolated_ecg(target_idx, :);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% RR:
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Passing in only those four samples i.e. 2, 3, 4, 5
		[mean_for_this_chunk, mean_rr_intervals, good_samples] =...
					find_samples_that_qualify(interpolated_ecg_within_win, rr_intervals);
		sliding_ksec_win.rr =...
			[sliding_ksec_win.rr;...
			mean_for_this_chunk,...
			mean_rr_intervals,...
			x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
			x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
			length(good_samples), this_sess_dosage_levels(d)];

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% PQRST:
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% First convert the RR samples into PQRST samples
		nFeatures = get_project_settings('nInterpolatedFeatures');
		
		pqrst_interpolated_ecg_within_win = [interpolated_ecg_within_win(1:end-1, (nFeatures/2)+1:nFeatures),...
	   					     interpolated_ecg_within_win(2:end, 1:nFeatures/2)];
		% Passing in only those four samples i.e. 2, 3, 4, 5
		[mean_for_this_chunk, mean_rr_intervals, good_samples] =...
					find_samples_that_qualify(pqrst_interpolated_ecg_within_win, rr_intervals);
		sliding_ksec_win.pqrst =...
			[sliding_ksec_win.pqrst;...
			mean_for_this_chunk,...
			mean_rr_intervals,...
			x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
			x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
			length(good_samples), this_sess_dosage_levels(d)];
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mean_for_this_chunk, mean_rr_intervals, good_samples] = find_samples_that_qualify(interpolated_ecg_within_win, rr_intervals)

nStddev = get_project_settings('how_many_std_dev');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
mean_for_this_chunk = zeros(1, size(interpolated_ecg_within_win, 2));
mean_rr_intervals = 0;
good_samples = [];

if ~isempty(interpolated_ecg_within_win)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Standardizing the samples for those four samples. Recall the standardizing is done per sample
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Gathering mean
	sample_means = mean(interpolated_ecg_within_win, 2);
	% Gathering the std dev
	sample_std = std(interpolated_ecg_within_win, [], 2);
	% standardizing the instances
	std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, interpolated_ecg_within_win,...
								sample_means), sample_std);
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(std_interpolated_ecg, 1);
	std_features = std(std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - nStddev*std_features, size(std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + nStddev*std_features, size(std_interpolated_ecg, 1), 1);
	good_samples = find(sum(std_interpolated_ecg >= lower &...
			        std_interpolated_ecg <= upper, 2) == nInterpolatedFeatures);

	% Only those samples that qualify. If this results in [2, 3] then mean_for_this_chunk will be
	% mean over samples [3, 4] since 3 qnd 4 are in positions 2 and 3
	if ~isempty(good_samples)
		mean_for_this_chunk = mean(std_interpolated_ecg(good_samples, :), 1);
		mean_rr_intervals = mean(rr_intervals(good_samples, :), 1);
	end
end

