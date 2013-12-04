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
% ecg_mat = ecg_mat - conv(ecg_mat, h, 'same');
% ecg_mat = ecg_mat(filter_size/2:end-filter_size/2);
% plot(ecg_mat)

% temp = ecg_mat(1.919*10^6+2000:1.919*10^6+4000, 7); % good results but very small chunk
% temp = ecg_mat(:, 7); % crap, only 39,201 all over the place though
temp = ecg_mat([1.29e+5:7.138e+5, 7.806e+5:3.4e+6, 3.515e+6:size(ecg_mat, 1)]);
% temp = ecg_mat(1.881e+6:1.881e+6+2500); % good results but very small chunk
plot(temp)

keyboard

csvwrite(sprintf('/home/anataraj/NIH-craving/ecgpuwave/osea20-gcc/P20_040d.csv'), temp);

