function[] = ecg_class_demo()

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');

subject_id = 'P20_079';
subject_profile = load(fullfile(result_dir, subject_id, sprintf('subject_profile.mat')));

event = 2;
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_start_hh = subject_profile.events{1, event}.start_time(1);
event_start_mm = subject_profile.events{1, event}.start_time(2);
event_end_hh = subject_profile.events{1, event}.end_time(1);
event_end_mm = subject_profile.events{1, event}.end_time(2);

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

start_temp = find(ecg_mat(:, 4) == event_start_hh &...
		  ecg_mat(:, 5) == event_start_mm);
end_temp = find(ecg_mat(:, 4) == event_end_hh &...
		ecg_mat(:, 5) == event_end_mm);

x1 = ecg_mat(start_temp(1):end_temp(end), end) .* 0.001220703125;
[rr1, rs] = rrextract(x1, 250, 0.02);

keyboard

time_matrix1 = ecg_mat(start_temp(1):end_temp(end), 4:6)';
time_matrix1 = sprintf('%d:%d:%02.0f*', time_matrix1);
time_matrix1 = regexp(time_matrix1, '*', 'split');

event = 1;
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_start_hh = 9;
event_start_mm = 20;
event_end_hh = 9;
event_end_mm = 58;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

start_temp = find(ecg_mat(:, 4) == event_start_hh &...
		  ecg_mat(:, 5) == event_start_mm);
end_temp = find(ecg_mat(:, 4) == event_end_hh &...
		ecg_mat(:, 5) == event_end_mm);

x2 = ecg_mat(start_temp(1):end_temp(end), end) .* 0.001220703125;
[rr2, rs] = rrextract(x2, 250, 0.05);
time_matrix2 = ecg_mat(start_temp(1):end_temp(end), 4:6)';
time_matrix2 = sprintf('%d:%d:%02.0f*', time_matrix2);
time_matrix2 = regexp(time_matrix2, '*', 'split');

P20_079_ecg = struct();
P20_079_ecg.base = x2;
P20_079_ecg.base_rr = rr2;
P20_079_ecg.base_time = time_matrix2;
P20_079_ecg.bike = x1;
P20_079_ecg.bike_rr = rr1;
P20_079_ecg.bike_time = time_matrix1;

save('/home/anataraj/NIH-craving/misc_mats/P20_079_base_bike.mat', '-struct', 'P20_079_ecg');

%{
font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

a = load('results/P20_079/bike_slide30_win.mat');
b = load('results/P20_079/cocn_slide30_win.mat');
c = find(b.pqrst_mat(:, end-1) == -3 & b.pqrst_mat(:, end) == 0);
figure();
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
plot(mean(a.pqrst_mat(:, 1:100)), 'b', 'LineWidth', 2);
hold on; plot(mean(b.pqrst_mat(c, 1:100)), 'r', 'LineWidth', 2);
grid on;
xlabel('Time(standardized)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Millivolts(Normalized)', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
x_ticks = get(gca, 'XTickLabel');
set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
legend('Physical Exercise', 'Baseline');
file_name = sprintf('/home/anataraj/Presentations/Images/p20_079_base_exer');
saveas(gcf, file_name, 'pdf') % Save figure

subject_id = 'P20_088';
subject_sensor = 'Sensor_2';
subject_timestamp = '2013_08_21-07_51_04';
event_start_hh = 11;
event_start_mm = 15;
event_end_hh = 12;
event_end_mm = 15;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

start_temp = find(ecg_mat(:, 4) == event_start_hh &...
		  ecg_mat(:, 5) == event_start_mm);
end_temp = find(ecg_mat(:, 4) == event_end_hh &...
		ecg_mat(:, 5) == event_end_mm);

x3 = ecg_mat(start_temp(1):end_temp(end), end) .* 0.001220703125;
time_matrix3 = ecg_mat(start_temp(1):end_temp(end), 4:6)';
time_matrix3 = sprintf('%d:%d:%02.0f*', time_matrix3);
time_matrix3 = regexp(time_matrix3, '*', 'split');

P20_088_ecg = struct();
P20_088_ecg.base = x3;
P20_088_ecg.base_rr = [];
P20_088_ecg.base_time = time_matrix3;

keyboard

save('/home/anataraj/NIH-craving/misc_mats/P20_088_garbage.mat', '-struct', 'P20_088_ecg');
%}

