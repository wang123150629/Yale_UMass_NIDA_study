function[] = interpolate_phone_data()

subject_id = 'P20_061';
subject_sensor = 'Sensor_100';
subject_timestamp = '2013_01_18-00_01_01';

close all;

data_dir = get_project_settings('data');
new_mat = [];

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
						sprintf('%s_ECG_noninterpolated.csv', subject_timestamp)), 1, 0);
assert(sum(diff(ecg_mat(:, 1)) > 0) == 0);
assert(sum(diff(ecg_mat(:, 2)) > 0) == 0);
assert(sum(diff(ecg_mat(:, 3)) > 0) == 0);
matlab_time = datenum(ecg_mat(:, 1:end-1));
unix_time = round(8.64e7 * (matlab_time - datenum('1970', 'yyyy')));
break_points = [0, find(diff(unix_time) > 1000 | diff(unix_time) < -1000)', size(ecg_mat, 1)];

for b = 1:length(break_points)-1
	new_timestamp = unix_time(break_points(b)+1):4:unix_time(break_points(b+1));

	x_length = length(break_points(b)+1:break_points(b+1));
	xi = linspace(1, x_length, length(new_timestamp));
	interpol_data = interp1(1:x_length, ecg_mat(break_points(b)+1:break_points(b+1), end), xi, 'pchip')';

	%plot(interpol_data, 'r');
	%hold on; plot(ecg_mat(break_points(b)+1:break_points(b+1), end));
	%sprintf('%d--%d:%d', break_points(b)+1, break_points(b+1), size(interpol_data, 2) - length(break_points(b)+1:break_points(b+1)))

	assert(length(new_timestamp) == length(interpol_data));
	new_timestamp = str2num(datestr(datenum('1970', 'yyyy') + new_timestamp / 864e5, 'yyyy, mm, dd, HH, MM, SS.FFF'));
	new_mat = [new_mat; new_timestamp, interpol_data];
end
new_mat = [zeros(1, size(new_mat, 2)); new_mat];

csvwrite(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
						sprintf('%s_ECG.csv', subject_timestamp)), new_mat);

