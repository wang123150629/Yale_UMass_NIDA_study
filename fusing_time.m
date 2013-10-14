function[] = fusing_time()

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

event = 1;
subject_id = 'P20_040';
subject_profile = subject_profiles(subject_id);
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_label = subject_profile.events{event}.label;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
% ecg_mat = ecg_mat(3.5*10^6:end, :);
% ecg_mat = ecg_mat(1:2.39*10^6+1, :);
ecg_mat(:, end) = ecg_mat(:, end) .* 0.001220703125;

ss = find(ecg_mat(:, 4) == 13.0000 & ecg_mat(:, 5) == 14.0000 & ecg_mat(:, 6) == 56.4360);
tt = find(ecg_mat(:, 4) == 15.0000 & ecg_mat(:, 5) == 54.0000 & ecg_mat(:, 6) == 16.4360);
lp = load(fullfile(results_dir, 'labeled_peaks', sprintf('P20_040_1_3pm_chunk.mat')));
labeled_peaks = zeros(3, size(ecg_mat, 1));
labeled_peaks(1, :) = ecg_mat(:, 7)';

peak_thres = 0.02;
[maxtab, mintab] = peakdet(ecg_mat(:, 7), peak_thres);
assert(isempty(intersect(maxtab(:, 1), mintab(:, 1))));
labeled_peaks(2, maxtab(:, 1)) = maxtab(:, 2);
labeled_peaks(2, mintab(:, 1)) = mintab(:, 2);
labeled_peaks(3, maxtab(:, 1)) = 100;
labeled_peaks(3, mintab(:, 1)) = 100;
labeled_peaks(2:3, ss:tt) = lp.labeled_peaks(2:3,:);
save(fullfile(results_dir, 'labeled_peaks', sprintf('P20_040_cocaine_day.mat')), 'labeled_peaks');

keyboard

% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
hr_time_entries = find(behav_mat(:, end) > 0);

% New file : Six labels P, Q, R, S, T, U - Unknown
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));
% Reading off data from the interface file
ecg_data = labeled_peaks(1, :);
peak_idx = labeled_peaks(2, :) > 0;
behav_hr = ones(size(ecg_data)) .* -1;

for h = 1:length(hr_time_entries)
	match_hh = behav_mat(hr_time_entries(h), 3) == (ecg_mat(:, 4) .* peak_idx');
	match_mm = behav_mat(hr_time_entries(h), 4) == (ecg_mat(:, 5) .* peak_idx');
	match_timestamp = find(match_hh & match_mm);
	if ~isempty(match_timestamp)
		behav_hr(match_timestamp(1)) = behav_mat(hr_time_entries(h), end);
	end
end

save(fullfile(results_dir, 'labeled_peaks', sprintf('%s_behav_hr.mat', subject_id)), 'behav_hr');

