function[] = prop_up_subject(subject_id)

switch subject_id
case 'P20_036'
	target_sessions = {'2012_05_30-10_13_20', '2012_05_30-15_46_41', '2012_05_30-17_11_16'};
case 'P20_039'
	target_sessions = {'2012_06_14-09_25_42', '2012_06_14-12_30_31', '2012_06_14-12_32_37', '2012_06_14-13_04_07', '2012_06_14-13_06_13'};
end
target_sensor = 'Sensor_1';

data_dir = get_project_settings('data');

ecg_mat = [];
for t = 1:length(target_sessions)
	hold_ecg = csvread(fullfile(data_dir, 'missing_data_subjects', subject_id, 'phoneecg',...
						sprintf('%s_ECG.csv', target_sessions{t})), 1, 0);
	ecg_mat = [ecg_mat; hold_ecg];
end

target_file_name = fullfile(data_dir, subject_id, target_sensor, target_sessions{1});
if ~exist(target_file_name)
	mkdir(target_file_name);
end
csvwrite(fullfile(target_file_name, sprintf('%s_ECG.csv', target_sessions{1})), ecg_mat);
disp(sprintf('Make sure to add ''Time,EcgWaveform'' as the first row of this .csv file you just created!'));

unique_date = ecg_mat(1, 1:3);
only_time = ecg_mat(:, 4:6);
only_time(:, end) = floor(only_time(:, end));
unique_time = unique(only_time, 'rows');
summary_mat = zeros(size(unique_time, 1), 40);
summary_mat(:, 1) = unique_date(end);
summary_mat(:, 2) = unique_date(2);
summary_mat(:, 3) = unique_date(1);
summary_mat(:, 4:6) = unique_time;

[expo, mant] = strtok(num2str(ecg_mat(1, 6)), '.');
mant = str2num(mant);
summary_mat(:, 6) = summary_mat(:, 6) + mant;
csvwrite(fullfile(target_file_name, sprintf('%s_Summary.csv', target_sessions{1})), summary_mat);
disp(sprintf('Make sure to add ''hh, mm, etc'' as the first row of this .csv file you just created!'));

