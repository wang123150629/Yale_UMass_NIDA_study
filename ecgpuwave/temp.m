function[] = temp()

results_dir = get_project_settings('results');
data_dir = get_project_settings('data');
plot_dir = get_project_settings('plots');

subject_id = 'P20_040';
subject_sensor = 'Sensor_1';
subject_timestamp = '2012_06_27-09_21_36';
filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);
analysis_id = '131111a';

% original ecg samples
original_file = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
ecg_data = original_file(:, end);
ecg_data = ecg_data([1.29e+5:7.138e+5, 7.806e+5:3.4e+6, 3.515e+6:size(ecg_data, 1)]);

temp2 = load(sprintf('/home/anataraj/NIH-craving/misc_mats/P20_040_crf_lab_peaks.mat'));
temp2 = temp2.temp;

keyboard

% Input from crf + sparse coding
crf_lbl_file = load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_cocaine_time.mat', subject_id)));
ecg_raw = crf_lbl_file.labeled_peaks(1, :);
ecg_data2 = ecg_raw - conv(ecg_raw, h, 'same');
ecg_data2 = ecg_data2(filter_size/2:end-filter_size/2);

% Output from crf + sparse coding
temp = load(fullfile(plot_dir, 'sparse_coding', analysis_id(1:7), sprintf('%s_labelled_set.mat', analysis_id)));

