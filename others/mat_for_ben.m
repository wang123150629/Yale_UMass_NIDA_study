function[] = mat_for_ben(sparse_coding, first_baseline_subtract, lambda)

close all;

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');

window_size = 25;
nDictionayElements = 100;
nIterations = 1000;
filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

subject_id = 'P20_040';
event = 1;
subject_profile = subject_profiles(subject_id);
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;

% New file : Six labels P, Q, R, S, T, U - Unknown
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));

% Reading off data from the interface file
ecg_raw = labeled_peaks(1, :);

if first_baseline_subtract
	% Performing baseline correction
	ecg_data = ecg_raw - conv(ecg_raw, h, 'same');
else
	ecg_data = ecg_raw;
end

ecg_data = ecg_data(filter_size/2:end-filter_size/2);

peak_idx = labeled_peaks(2, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
peak_idx(1:window_size) = 0;
peak_idx(end-window_size:end) = 0;

labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);
labeled_idx(1:window_size) = 0;
labeled_idx(end-window_size:end) = 0;

peak_labels = labeled_peaks(3, :);
peak_labels = peak_labels(filter_size/2:end-filter_size/2);

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = find(peak_idx & labeled_idx);

param = struct();
if sparse_coding
	unlabeled_idx = find(peak_idx - labeled_idx);
	assert(~isempty(unlabeled_idx));
	unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
	unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
	ecg_learn = ecg_data(unlabeled_idx)';

	param.K = nDictionayElements;  % learns a dictionary with 100 elements
	param.iter = nIterations;  % let us see what happens after 1000 iterations
	param.lambda = lambda;
	param.numThreads = 4; % number of threads
	param.batchsize = 400;
	param.approx = 0;
	param.verbose = false;

	D = mexTrainDL(ecg_learn, param);
end

all_samples_win_idx = [labeled_peaks_idx - window_size; labeled_peaks_idx + window_size];
all_samples_win_idx = floor(linspaceNDim(all_samples_win_idx(1, :), all_samples_win_idx(2, :), window_size*2+1));
ecg_all_samples = ecg_data(all_samples_win_idx)';
ecg_all_Y = peak_labels(labeled_peaks_idx);
assert(~any(ecg_all_Y <= 0 | ecg_all_Y >= 100));

if sparse_coding
	param.mode = 2;
	all_alpha = mexLasso(ecg_all_samples, D, param);
else
	all_alpha = ecg_all_samples;
end

preprocessed_ecg = [all_alpha', ecg_all_Y'];
save('preprocessed_ecg.mat', 'preprocessed_ecg');

keyboard

