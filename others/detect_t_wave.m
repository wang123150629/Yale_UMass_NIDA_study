function [] = detect_t_wave(peak_det_appr)

close all

root_dir = pwd;
data_dir = fullfile(root_dir, 'data');
subject_id = 'P20_048';
subject_session = '2012_08_17-10_15_55';

time_resolution = 60; % seconds

% Loading the raw ECG data
% The raw ECG data is sampled every 4 milliseconds so for every 250 (250 x 4 = 1000 = 1 second) samples we will have an entry in the summary table. Now the summary table has entries for sec1.440 i.e. sec1.440 to sec2.436 are summarized into this entry.
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);
% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_summary_clean.csv', subject_session)), 1, 0);
% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);

% Fetching the absolute and event indices
index_maps = find_start_end_time(summary_mat, behav_mat, time_resolution);

dosage_levels = [8, 16, 32];
for d = 1:length(dosage_levels)
	% For the d mg infusions, in the first session, fetch the associated indices from the absolute time axis
	hold_start_end_times = intersect(index_maps.behav(find(behav_mat(:, 6) == dosage_levels(d))),...
				index_maps.behav(find(behav_mat(:, 5) == 1)));
	start_time = hold_start_end_times(1) - (index_maps.summary(1)-1);
	end_time = hold_start_end_times(end)+60 - index_maps.summary(1);
	assert(length(start_time:60:end_time) == length(hold_start_end_times));
	start_time = (start_time - 1) * 250 + 1;
	end_time = (end_time - 1) * 250 + 1;

	switch peak_det_appr
	case 1
		% this detector moves from left to right while keeping track of the max value and its associted index when it comes across a value even greater then what it is holding, it updates itself. If it comes across a value which is delta less than what it is holding then it write out the max value and repeats the procedure for the minimum value. Note the key is that it always looks at its right to determine what to write out as max/min.
		end_time = start_time + 1000;
		x = start_time:end_time;
		noisy_wave = ecg_mat(x, 7);

		delta = 30; % in microvolts
		[maxtab, mintab] = peakdet(noisy_wave, delta);
		maxtab1 = maxtab(2:end, :);
		maxtab = maxtab(1:end-1, :);
		slope = (maxtab1(:, 2) - maxtab(:, 2)) ./ (maxtab1(:, 1) - maxtab(:, 1));
		neg_slope_idx = find(slope < 0);
		neg_slope_mat = [maxtab1(neg_slope_idx, :), slope(neg_slope_idx)];
		filtered_neg_slope_idx = find(abs(neg_slope_mat(:, 3)) > 1);
		neg_slope_mat(:, 1:2)
		neg_slope_mat(filtered_neg_slope_idx, 1:2)

		figure(); set(gcf, 'Position', [10, 10, 800, 800]);
		plot(1:length(noisy_wave), noisy_wave, 'b-'); hold on;
		plot(neg_slope_mat(filtered_neg_slope_idx, 1), neg_slope_mat(filtered_neg_slope_idx, 2), 'go');
		xlabel('Time(40 milliseconds)');
		ylabel('microvolts');
		title(sprintf('samples from %dmm dosage', dosage_levels(d)));

		% x = start_time:end_time;
		% x = start_time+230000:start_time+234000;
		% maxtab1 = maxtab(2:end, :);
		% maxtab = maxtab(1:end-1, :);
		% pos_slope_idx = find((maxtab1(:, 2) - maxtab(:, 2)) ./ (maxtab1(:, 1) - maxtab(:, 1)) > 0);
		% figure(); hist(maxtab(pos_slope_idx, 2), 100);
		% mean(maxtab(pos_slope_idx, 2))
		% std(maxtab(pos_slope_idx, 2))
		% plot(maxtab(:, 1), maxtab(:, 2), 'ro');
		% plot(mintab(:, 1), mintab(:, 2), 'go');
		% plot(maxtab(pos_slope_idx, 1), maxtab(pos_slope_idx, 2), 'ro');
	otherwise
		error('Invalid peak detection algorithm');
	end
end

