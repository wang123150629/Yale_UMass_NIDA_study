function[] = craving_driver()

number_of_subjects = 3;
[subject_ids, subject_sessions] = get_subject_ids(number_of_subjects);

for s = 1:number_of_subjects
	[data_mat_columns, summary_mat, behav_mat] = read_data(subject_ids{s}, subject_sessions{s});
	plot_time_series(data_mat_columns, summary_mat, behav_mat, subject_ids{s});
end

close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[data_mat_columns, summary_mat, behav_mat] = read_data(subject_id, subject_session)

root_dir = pwd;
data_dir = fullfile(root_dir, 'data');

summary_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_summary_clean.csv', subject_session)), 1, 0);
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);

% ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);
% summary_mat = preprocess(summary_mat);
% click_information(subject_id, behav_mat, true);

data_mat_columns = struct();
data_mat_columns.HR = 7;
data_mat_columns.BR = 8;
data_mat_columns.ECG_amp = 18;
data_mat_columns.ECG_noise = 19;
data_mat_columns.HR_conf = 20;
data_mat_columns.HR_var = 21;
data_mat_columns.activity = 11;
data_mat_columns.peak_acc = 12;
data_mat_columns.vertical = [26, 27];
data_mat_columns.lateral = [28, 29];
data_mat_columns.saggital = [30, 31];
data_mat_columns.core_temp = 37;
data_mat_columns.others = [1:6, 9:10, 13:17, 22:25, 32:36, 38:40];

