function[clean_interpolated_ecg] = preprocess_ecg_data(subject_id, subject_session, subject_threshold)

data_dir = get_project_settings('data');
write_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
how_many_std_dev = 3;
nInterpolatedFeatures = 150;
time_resolution = 60; % seconds

% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_summary_clean.csv', subject_session)), 1, 0);
% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
% Fetching the absolute and event indices
index_maps = find_start_end_time(summary_mat, behav_mat, time_resolution);
% Loading the raw ECG data
% The raw ECG data is sampled every 4 milliseconds so for every 250 (250 x 4 = 1000 = 1 second) samples we will have an entry in the summary table. Now the summary table has entries for sec1.440 i.e. sec1.440 to sec2.436 are summarized into this entry.
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);

dosage_levels = [-3, 8, 16, 32];
assert(length(subject_threshold) == length(dosage_levels));
cut_off_heart_rate = [150, 300]; % i.e 150 x 4 = 600 milliseconds to 300 x 4 = 1200 milliseconds

clean_interpolated_ecg = [];
rr_ten_minute_means = [];
pqrst_ten_minute_means = [];
for d = 1:length(dosage_levels)
	disp(sprintf('dosage=%d', dosage_levels(d)));
	interpolated_ecg = [];
	% For the d mg infusion ONLY in the first session, fetch the associated indices from the absolute time axis.
	% For instance this fetches 11100:60:12660 = 27 time points
	dosg_start_end = find(behav_mat(:, 6) == dosage_levels(d));
	if dosage_levels(d) < 0
		sess_start_end = find(behav_mat(:, 5) == 0);
		title_str = sprintf('session=1, baseline');
	else
		sess_start_end = find(behav_mat(:, 5) == 1);
		title_str = sprintf('session=1, dosage=%d', dosage_levels(d));
	end
	dosg_sess_start_end = intersect(dosg_start_end, sess_start_end);
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
	x_time = ecg_mat(raw_start_time:raw_end_time, 4:6);

	%{
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Plot 1: Raw ECG for baselines, 8mg, etc
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	plot(x, 'b-');
	xlabel('Time(4ms resolution)'); ylabel('millivolts');
	title(sprintf('%s, raw ECG', title_str)); ylim([0, 5]);
	file_name = sprintf('%s/subj_%s_dos_%d_raw_chunk', write_dir, subject_id, d);
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
			interpol_data = interp1(1:x_length, x(rr_start_end(s, 1):rr_start_end(s, 2)), xi, 'pchip');
			if max(interpol_data) <= 5 & min(interpol_data) >= 0
				interpolated_ecg = [interpolated_ecg; interpol_data];
				hold_start_end_indices = [hold_start_end_indices; rr_start_end(s, :)];
				valid_rr_intervals = [valid_rr_intervals; rr_start_end(s, 2) - rr_start_end(s, 1)];
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
	file_name = sprintf('%s/subj_%s_dos_%d_raw_rr', write_dir, subject_id, d);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
	%}

	% Gathering mean prior to any filter
	rr_sample_means = mean(interpolated_ecg, 2);
	% Gathering the std prior to any filter
	rr_sample_std = std(interpolated_ecg, [], 2);
	% standardizing the instances
	rr_std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, interpolated_ecg, rr_sample_means),...
	 				rr_sample_std);
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(rr_std_interpolated_ecg, 1);
	std_features = std(rr_std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - how_many_std_dev*std_features, size(rr_std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + how_many_std_dev*std_features, size(rr_std_interpolated_ecg, 1), 1);
	good_rr_samples = sum(rr_std_interpolated_ecg > lower &...
			      rr_std_interpolated_ecg < upper, 2) == nInterpolatedFeatures;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Plot 3: Interpolated ECG but teasing apart as good and bad samples
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	figure('visible', 'off'); set(gcf, 'Position', [10, 10, 1200, 800]);
	colors = jet(size(rr_std_interpolated_ecg, 1));

	subplot(2, 1, 1);
	plot(rr_std_interpolated_ecg(good_rr_samples, :)'); hold on;
	plot(mean(rr_std_interpolated_ecg(good_rr_samples, :), 1), 'k-', 'LineWidth', 2);
	title(sprintf('%s\nGood samples=%d, std dev=%d', title_str, sum(good_rr_samples), how_many_std_dev));
	xlabel('Time(milliseconds)'); ylabel('std millivolts');
	set(gca, 'XTickLabel', str2num(get(gca, 'XTickLabel')) * 4);

	subplot(2, 1, 2);
	plot(rr_std_interpolated_ecg(~good_rr_samples, :)'); hold on;
	plot(mean(rr_std_interpolated_ecg(good_rr_samples, :), 1), 'k-', 'LineWidth', 2);
	title(sprintf('%s\nBad samples=%d, std dev=%d', title_str,...
				length(good_rr_samples) - sum(good_rr_samples), how_many_std_dev));
	xlabel('Time(milliseconds)'); ylabel('std millivolts');
	set(gca, 'XTickLabel', str2num(get(gca, 'XTickLabel')) * 4);
	file_name = sprintf('%s/subj_%s_dos_%d_rr_inter', write_dir, subject_id, d);
	savesamesize(gcf, 'file', file_name, 'format', image_format);

	disp(sprintf('No. of samples=%d', sum(good_rr_samples)));
	clean_interpolated_ecg = [clean_interpolated_ecg; rr_std_interpolated_ecg(good_rr_samples, :),...
					valid_rr_intervals(good_rr_samples),...
					rr_sample_means(good_rr_samples),...
					rr_sample_std(good_rr_samples),...
					repmat(d, sum(good_rr_samples), 1)];
	if dosage_levels(d) > 0
		clean_interpolated_ecg = [clean_interpolated_ecg; rr_std_interpolated_ecg(good_rr_samples, :),...
					valid_rr_intervals(good_rr_samples),...
					rr_sample_means(good_rr_samples),...
					rr_sample_std(good_rr_samples),...
					repmat(length(dosage_levels)+1, sum(good_rr_samples), 1)];
	end

	pqrst_interpolated_ecg = [interpolated_ecg(1:end-1, 76:150), interpolated_ecg(2:end, 1:75)];
	% standardizing the instances
	pqrst_std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, pqrst_interpolated_ecg,...
			mean(pqrst_interpolated_ecg, 2)), std(pqrst_interpolated_ecg, [], 2));
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(pqrst_std_interpolated_ecg, 1);
	std_features = std(pqrst_std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - how_many_std_dev*std_features, size(pqrst_std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + how_many_std_dev*std_features, size(pqrst_std_interpolated_ecg, 1), 1);
	good_pqrst_samples = sum(pqrst_std_interpolated_ecg > lower &...
			         pqrst_std_interpolated_ecg < upper, 2) == nInterpolatedFeatures;

	% This is taking the entire, say baseline, session and breaking it into ten minute intervals
	samples_clusters = [1:(250 * 60 * 10):size(x, 1), size(x, 1)];
	% This aligns the start and end times into a matrix form like [start 1, end 1; start 2, end 2, etc]
	samples_clusters = [samples_clusters(1:end-1); samples_clusters(2:end)-1]';
	for s = 1:size(samples_clusters, 1)
		% Fishing out exactly how many RR interpolated chunks are within this ten minute interval
		target_idx = find(hold_start_end_indices(:, 2) >= samples_clusters(s, 1) &...
				  hold_start_end_indices(:, 2) <= samples_clusters(s, 2));
		% This is the case since some of the rr's are not of valid length and the others might be
		% 3 std dev or more from the mean. By intersecting we pick only the qualified ones
		rr_target_idx = intersect(target_idx, find(good_rr_samples));
		if ~isempty(rr_target_idx)
			rr_ten_minute_means = [rr_ten_minute_means;...
				mean(rr_std_interpolated_ecg(rr_target_idx, :), 1),...
				x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
				x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
				length(rr_target_idx), d];
		end

		% This is the case since some of the rr's are not of valid length and the others might be
		% 3 std dev or more from the mean. By intersecting we pick only the qualified ones
		pqrst_target_idx = intersect(target_idx, find(good_pqrst_samples));
		if ~isempty(pqrst_target_idx)
			pqrst_ten_minute_means = [pqrst_ten_minute_means;...
				mean(pqrst_std_interpolated_ecg(pqrst_target_idx, :), 1),...
				x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
				x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
				length(pqrst_target_idx), d];
		end
	end
end

ten_minute_means = struct();
ten_minute_means.rr = rr_ten_minute_means;
ten_minute_means.pqrst = pqrst_ten_minute_means;
save(fullfile(data_dir, subject_id, subject_session, sprintf('ten_minute_means')), 'ten_minute_means');
save(fullfile(data_dir, subject_id, subject_session, sprintf('clean_interpolated_ecg')), 'clean_interpolated_ecg');
close all;

