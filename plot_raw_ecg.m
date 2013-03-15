function[] = plot_raw_ecg(subject_id, event, varargin)

% plot_raw_ecg('P20_040', 'cocn')

switch event
case 'cocn', event = 1;
case 'exer', event = 2;
case 'mph2', event = 3;
case 'hab', event = 4;
case 'nta', event = 5;
end

subject_profile = subject_profiles(subject_id);

data_dir = get_project_settings('data');
subject_id =  subject_profile.subject_id;
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_label = subject_profile.events{event}.label;

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
if length(varargin) == 2
	start_time = varargin{1}; end_time = varargin{2};
else
	start_time = 1; end_time = size(ecg_mat, 1);
end

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(ecg_mat(start_time:end_time, end) .* 0.004882812500000, 'b-');
title(sprintf('%s, %s session', get_project_settings('strrep_subj_id', subject_id), event_label));
xlabel('Time(milliseconds)'); ylabel('Millivolts');
% file_name = sprintf('/home/anataraj/NIH-craving/poster_plots/raw_ecg_cocn');
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

