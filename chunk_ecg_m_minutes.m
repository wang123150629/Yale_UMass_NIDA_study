function[] = chunk_ecg_m_minutes(preprocessed_data, subject_id)

result_dir = get_project_settings('results');
exp_sessions = get_project_settings('exp_sessions');
how_many_minutes_per_chunk = get_project_settings('how_many_minutes_per_chunk');

chunks_m_min = cell(1, length(exp_sessions));
for e = 1:length(exp_sessions)
	chunks_m_min{1, e} = make_plots(preprocessed_data{1, e}, subject_id, exp_sessions(e));
end
save(fullfile(result_dir, subject_id, sprintf('chunks_%d_min', how_many_minutes_per_chunk)), 'chunks_m_min');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[chunk_m_min_session] = make_plots(preprocessed_data, subject_id, experiment_session)

plot_dir = get_project_settings('plots');
result_dir = get_project_settings('results');
image_format = get_project_settings('image_format');
nStddev = get_project_settings('how_many_std_dev');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
dosage_levels = get_project_settings('dosage_levels');
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
how_many_minutes_per_chunk = get_project_settings('how_many_minutes_per_chunk');
% This data comes from pre-processing. We do not rely on project settings here since some sessions contain only some dosage levels 
this_sess_dosage_levels = preprocessed_data.dosage_levels;

chunk_m_min_session = struct();
chunk_m_min_session.rr_chunk_m_min_session = [];
chunk_m_min_session.pqrst_chunk_m_min_session = [];
for d = 1:length(this_sess_dosage_levels)
	title_str = sprintf('%s, sess=%d, dos=%d', get_project_settings('strrep_subj_id', subject_id),...
							experiment_session, this_sess_dosage_levels(d));

	target_dosage_idx = preprocessed_data.dosage_labels == this_sess_dosage_levels(d); % pick out rows
	interpolated_ecg = preprocessed_data.interpolated_ecg(target_dosage_idx, :); % pick out corresponding features
	hold_start_end_indices = preprocessed_data.hold_start_end_indices(target_dosage_idx, :); % start end indices
	rr_intervals = preprocessed_data.valid_rr_intervals(target_dosage_idx, :); % start end indices
	assert(all(hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) >= cut_off_heart_rate(1) &...
	           hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) <= cut_off_heart_rate(2)));
	x_size = preprocessed_data.x_size(this_sess_dosage_levels(d) == dosage_levels);
	x_time = preprocessed_data.x_time{this_sess_dosage_levels(d) == dosage_levels};

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% RR
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Gathering mean
	rr_sample_means = mean(interpolated_ecg, 2);
	% Gathering the std dev
	rr_sample_std = std(interpolated_ecg, [], 2);
	% standardizing the instances
	rr_std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, interpolated_ecg, rr_sample_means), rr_sample_std);
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(rr_std_interpolated_ecg, 1);
	std_features = std(rr_std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - nStddev*std_features, size(rr_std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + nStddev*std_features, size(rr_std_interpolated_ecg, 1), 1);
	good_rr_samples = sum(rr_std_interpolated_ecg > lower &...
			      rr_std_interpolated_ecg < upper, 2) == nInterpolatedFeatures;
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% PQRST
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	nFeatures = get_project_settings('nInterpolatedFeatures');
	pqrst_interpolated_ecg = [interpolated_ecg(1:end-1, (nFeatures/2)+1:nFeatures),...
				  interpolated_ecg(2:end, 1:nFeatures/2)];
	% Gathering mean
	pqrst_sample_means = mean(pqrst_interpolated_ecg, 2);
	% Gathering the std dev
	pqrst_sample_std = std(pqrst_interpolated_ecg, [], 2);
	% standardizing the instances
	pqrst_std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, pqrst_interpolated_ecg,...
			pqrst_sample_means), pqrst_sample_std);
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(pqrst_std_interpolated_ecg, 1);
	std_features = std(pqrst_std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - nStddev*std_features, size(pqrst_std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + nStddev*std_features, size(pqrst_std_interpolated_ecg, 1), 1);
	good_pqrst_samples = sum(pqrst_std_interpolated_ecg > lower &...
				 pqrst_std_interpolated_ecg < upper, 2) == nInterpolatedFeatures;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Plot 3: Interpolated ECG but teasing apart as good and bad samples
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	figure('visible', 'off'); set(gcf, 'Position', [10, 10, 1200, 800]);
	colors = jet(size(rr_std_interpolated_ecg, 1));

	subplot(2, 1, 1);
	plot(rr_std_interpolated_ecg(good_rr_samples, :)'); hold on;
	plot(mean(rr_std_interpolated_ecg(good_rr_samples, :), 1), 'k-', 'LineWidth', 2);
	title(sprintf('%s\nGood samples=%d, std dev=%d', title_str, sum(good_rr_samples), nStddev));
	xlabel('Time(milliseconds)'); ylabel('std millivolts');

	subplot(2, 1, 2);
	plot(rr_std_interpolated_ecg(~good_rr_samples, :)'); hold on;
	plot(mean(rr_std_interpolated_ecg(good_rr_samples, :), 1), 'k-', 'LineWidth', 2);
	title(sprintf('%s\nBad samples=%d, std dev=%d', title_str,...
				length(good_rr_samples) - sum(good_rr_samples), nStddev));
	xlabel('Time(milliseconds)'); ylabel('std millivolts');

	subplot(2, 1, 1);
	set(gca, 'XTickLabel', str2num(get(gca, 'XTickLabel')) * 4);
	subplot(2, 1, 2);
	set(gca, 'XTickLabel', str2num(get(gca, 'XTickLabel')) * 4);

	file_name = sprintf('%s/%s/subj_%s_expsess_%d_dos_%d_cleaned_ecg', plot_dir, subject_id, subject_id,...
						experiment_session, d);
	savesamesize(gcf, 'file', file_name, 'format', image_format);

	rr_sum = '';
	pqrst_sum = '';
	% This is taking the entire, say baseline, session and breaking it into m minute intervals
	samples_clusters = [1:(250 * 60 * how_many_minutes_per_chunk):x_size, x_size];
	% This aligns the start and end times into a matrix form like [start 1, end 1; start 2, end 2, etc]
	samples_clusters = [samples_clusters(1:end-1); samples_clusters(2:end)-1]';
	for s = 1:size(samples_clusters, 1)
		% Fishing out exactly how many RR interpolated chunks are within this m minute interval
		target_idx = find(hold_start_end_indices(:, 2) >= samples_clusters(s, 1) &...
				  hold_start_end_indices(:, 2) <= samples_clusters(s, 2));
		% This is the case since some of the rr's are not of valid length and the others might be
		% 3 std dev or more from the mean. By intersecting we pick only the qualified ones
		mean_for_this_chunk = zeros(1, size(rr_std_interpolated_ecg, 2));
		mean_rr_intervals = 0;
		rr_target_idx = intersect(target_idx, find(good_rr_samples));
		if ~isempty(rr_target_idx)
			mean_for_this_chunk = mean(rr_std_interpolated_ecg(rr_target_idx, :), 1);
			mean_rr_intervals = mean(rr_intervals(rr_target_idx, :), 1);
		end
		chunk_m_min_session.rr_chunk_m_min_session =...
			[chunk_m_min_session.rr_chunk_m_min_session;...
			mean_for_this_chunk,...
			mean_rr_intervals,...
			x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
			x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
			length(rr_target_idx), this_sess_dosage_levels(d)];
		rr_sum = strcat(rr_sum, sprintf('%d+', length(rr_target_idx)));

		% This is the case since some of the rr's are not of valid length and the others might be
		% 3 std dev or more from the mean. By intersecting we pick only the qualified ones
		mean_for_this_chunk = zeros(1, size(pqrst_std_interpolated_ecg, 2));
		mean_rr_intervals = 0;
		pqrst_target_idx = intersect(target_idx, find(good_pqrst_samples));
		if ~isempty(pqrst_target_idx)
			mean_for_this_chunk = mean(pqrst_std_interpolated_ecg(pqrst_target_idx, :), 1);
			mean_rr_intervals = mean(rr_intervals(pqrst_target_idx, :), 1);
		end
		chunk_m_min_session.pqrst_chunk_m_min_session =...
			[chunk_m_min_session.pqrst_chunk_m_min_session;...
			mean_for_this_chunk,...
			mean_rr_intervals,...
			x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
			x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
			length(pqrst_target_idx), this_sess_dosage_levels(d)];
		pqrst_sum = strcat(pqrst_sum, sprintf('%d+', length(pqrst_target_idx)));
	end
	assert(sum(good_rr_samples) == eval(rr_sum(1:end-1)));
	disp(sprintf('No. of good rr samples=%d', sum(good_rr_samples)));
	disp(sprintf('rr sum over %d mins %s=%d', how_many_minutes_per_chunk, rr_sum(1:end-1),...
						eval(rr_sum(1:end-1))));
	assert(sum(good_pqrst_samples) == eval(pqrst_sum(1:end-1)));
	disp(sprintf('No. of good pqrst samples=%d', sum(good_pqrst_samples)));
	disp(sprintf('pqrst sum over %d mins %s=%d', how_many_minutes_per_chunk, pqrst_sum(1:end-1),...
						eval(pqrst_sum(1:end-1))));
end

