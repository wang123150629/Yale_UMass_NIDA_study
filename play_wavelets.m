function[] = play_wavelets()

data_dir = get_project_settings('data');
subject_id = 'P20_048';
subject_profile = subject_profiles(subject_id);
event = 1;
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;

% ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
%		sprintf('%s_ECG_clean.csv', subject_timestamp)), 1, 0);
% ecg_mat = ecg_mat(:, end) .* 0.001220703125;
% [approximations, details] = wavelet_decompose(ecg_mat(1, 1:1000), 5, 'bior3.3');

load('sample_ecg.mat');
[approximations, details] = wavelet_decompose(a, 5, 'bior3.3');

keyboard

