function[] = fancy_plot_raw_ecg()

close all;

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

data_dir = get_project_settings('data');
result_dir = get_project_settings('results');
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
rr_thresholds = 0.05;
subject_id = 'P20_040';
subject_sensor = 'Sensor_1';
subject_timestamp = '2012_06_27-09_21_36';
time_window = 30;
event = 'cocn';
tr_percent = 60;
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);

y = [ecg_mat(0.64e+6:0.65e+6, 7) * 0.001220703125];
x = 1:length(y);
figure();
set(gcf, 'PaperPosition', [0 0 10 6]);
set(gcf, 'PaperSize', [10 6]);
plot(x, y, 'Linewidth', 2)
% x_ticks = (str2num(get(gca, 'XTickLabel'))) / 250;
x_ticks = round_to(linspace(1, 48, 11), 0);
x_ticks(1) = 1;
set(gca, 'XTick', 0:1000:10000);
set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
y_ticks = get(gca, 'YTickLabel');
set(gca, 'YTickLabel', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim([2.2, 2.8]);
xlim([1, length(y)]);
xlabel('Time(seconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
file_name = sprintf('/home/anataraj/Presentations/Ubicomp_Sep_2013/Images/raw_ecg_issues');
saveas(gcf, file_name, 'pdf') % Save figure

keyboard

y = [ecg_mat(0.63e+6:0.635e+6, 7) * 0.001220703125];
x = 1:length(y);
figure();
set(gcf, 'PaperPosition', [0 0 6 4]);
set(gcf, 'PaperSize', [6 4]);
plot(x, y, 'Linewidth', 1)
x_ticks = (str2num(get(gca, 'XTickLabel'))) / 250;
x_ticks(1) = 1;
set(gca, 'XTick', 0:1000:6000);
set(gca, 'XTickLabel', x_ticks, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim([2.3, 2.6]);
% y_ticks = get(gca, 'YTickLabel');
% set(gca, 'YTickLabel', y_ticks, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlim([0, length(y)]);
xlabel('Time(seconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylabel('Millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
file_name = sprintf('/home/anataraj/Presentations/Ubicomp_Sep_2013/Images/raw_ecg');
saveas(gcf, file_name, 'pdf') % Save figure

