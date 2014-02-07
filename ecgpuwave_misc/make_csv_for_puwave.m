function[] = make_csv_for_puwave()

data_dir = get_project_settings('data');
subject_id = 'P20_040';
subject_sensor = 'Sensor_1';
subject_timestamp = '2012_06_27-09_21_36';
filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
ecg_mat = ecg_mat(:, end);

% I am only choosing part of the ECG data from cocaine day since the parts with signal dropouts are causing the ECGPUWave toolboxes to break
magic_idx = get_project_settings('magic_idx', subject_id);
csvwrite(sprintf('/home/anataraj/NIH-craving/ecgpuwave/osea20-gcc/P20_040d.csv'), ecg_mat(magic_idx));

