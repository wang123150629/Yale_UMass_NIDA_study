function[] = plot_time_series(data_mat_columns, summary_mat, behav_mat, index_maps, subject_id)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
summ_mat_time_res = get_project_settings('summ_mat_time_res');
% length of event (infusion, clicks, etc) window in minutes. This will grab 5 x 60 = 300 samples before and after
event_window_length = get_project_settings('event_window_length');
dosage_levels = get_project_settings('dosage_levels');
vas_measures = get_project_settings('vas_measures');

if strcmp(subject_id, 'P20_036')
	% Since this was the first pilot subject the files have information organized this way
	data_mat_columns = struct();
	data_mat_columns.HR = 7;
	data_mat_columns.BR = 8;
	data_mat_columns.ECG_amp = 15;
	data_mat_columns.ECG_noise = 16;
	data_mat_columns.activity = 11;
	data_mat_columns.peak_acc = 12;
	data_mat_columns.vertical = [17, 18];
	data_mat_columns.lateral = [19, 20];
	data_mat_columns.saggital = [21, 22];
	% no core temperature, heart rate confidence and heart rate variance
end

click_indices = find(behav_mat(:, 7) == 1);
infusion_indices = find(behav_mat(:, 8) == 1);
vas_indices = find(behav_mat(:, 9) >= 0);

%------------------------------------------------------------------------------
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);

max_heart_rate = 170;
subplot(2, 1, 1);
[ax, h1, h2] = plotyy(index_maps.summary, summary_mat(:, data_mat_columns.HR), index_maps.behav(vas_indices), behav_mat(vas_indices, vas_measures(1))); hold on;
set(get(ax(1), 'Ylabel'), 'String', 'Heart rate');
set(get(ax(2), 'Ylabel'), 'String', 'VAS-High');
set(ax(1), 'ylim', [0, max_heart_rate]);
set(ax(2), 'ylim', [0, 13]);
set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(h1, 'LineStyle', '-');
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
plot_behav_data_on_top(min(summary_mat(:, data_mat_columns.HR)), max_heart_rate, dosage_levels, behav_mat, click_indices, infusion_indices, index_maps.behav);
xlabel('Time(seconds)');
title(sprintf('Subject %s', get_project_settings('strrep_subj_id', subject_id)));
grid on; set(gca, 'Layer', 'top');

max_breathing_rate = 35;
subplot(2, 1, 2);
[ax, h1, h2] = plotyy(index_maps.summary, summary_mat(:, data_mat_columns.BR), index_maps.behav(vas_indices), behav_mat(vas_indices, vas_measures(2))); hold on;
set(get(ax(1), 'Ylabel'), 'String', 'Breathing rate');
set(get(ax(2), 'Ylabel'), 'String', 'VAS-Stim');
set(ax(1), 'ylim', [0, max_breathing_rate]);
set(ax(2), 'ylim', [0, 13]);
set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(h1, 'LineStyle', '-');
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
plot_behav_data_on_top(min(summary_mat(:, data_mat_columns.BR)), max_breathing_rate, dosage_levels, behav_mat, click_indices, infusion_indices, index_maps.behav);
xlabel('Time(seconds)');
grid on; set(gca, 'Layer', 'top');

file_name = sprintf('%s/%s/subject_%s_summ_hr_br', plot_dir, subject_id, subject_id);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_behav_data_on_top(min_val, max_val, dosage_levels, behav_mat, click_indices, infusion_indices, behav_indices)

dosage_levels = sort(dosage_levels);
chunk_size = min_val:((max_val - min_val) / 15):max_val;
associated_entries = chunk_size(2:2+length(dosage_levels)); % Taking the second chunk and after
for d = 1:length(dosage_levels)
	target_idx = behav_mat(:, 6) == dosage_levels(d);
	plot(behav_indices(target_idx), associated_entries(d), 'mo');
end
plot(behav_indices(click_indices), chunk_size(end), 'k*');
plot(behav_indices(infusion_indices), chunk_size(end-1), 'r*');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
%------------------------------------------------------------------------------
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
subplot(2, 1, 1); plot(index_maps.summary, summary_mat(:, data_mat_columns.ECG_amp), 'b-');
ylabel('ECG Amp');
xlabel('Time(seconds)');
xlim([index_maps.time_axis(1), index_maps.time_axis(end)]);
grid on; set(gca, 'Layer', 'top');
title(sprintf('Subject %s', strrep(subject_id, '_', '-')));

subplot(2, 1, 2); plot(index_maps.summary, summary_mat(:, data_mat_columns.ECG_noise), 'b-');
ylabel('ECG Noise');
xlabel('Time(seconds)');
xlim([index_maps.time_axis(1), index_maps.time_axis(end)]);
grid on; set(gca, 'Layer', 'top');

file_name = sprintf('%s/subject_%s_summ_ecg', plot_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

%------------------------------------------------------------------------------
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
max_activity_level = 2;
subplot(2, 1, 1);
[ax, h1, h2] = plotyy(index_maps.summary, summary_mat(:, data_mat_columns.activity), index_maps.behav(vas_indices), behav_mat(vas_indices, 19)); hold on;
set(get(ax(1), 'Ylabel'), 'String', 'Activity');
set(get(ax(2), 'Ylabel'), 'String', 'VAS-Cocaine');
set(ax(1), 'ylim', [0, max_activity_level]);
set(ax(2), 'ylim', [0, 10]);
set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
set(h1, 'LineStyle', '-');
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
plot_behav_data_on_top(min(summary_mat(:, data_mat_columns.activity)), max_activity_level, dosage_levels, behav_mat, click_indices, infusion_indices, index_maps.behav);
xlabel('Time(seconds)');
grid on; set(gca, 'Layer', 'top');
title(sprintf('Subject %s', strrep(subject_id, '_', '-')));

if isfield(data_mat_columns, 'core_temp')
	% since core body temperature is between 33 and 41 degree celcius
	valid_temp_idx = summary_mat(:, data_mat_columns.core_temp) <= 41;
	subplot(2, 1, 2);
	[ax, h1, h2] = plotyy(index_maps.summary(valid_temp_idx), summary_mat(valid_temp_idx, data_mat_columns.core_temp), index_maps.behav(vas_indices), behav_mat(vas_indices, 14)); hold on;
	set(get(ax(1), 'Ylabel'), 'String', 'Core body temperature');
	set(get(ax(2), 'Ylabel'), 'String', 'VAS-Anxious');
	% set(ax(1), 'ylim', [0, 41]);
	set(ax(2), 'ylim', [0, 10]);
	set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(h1, 'LineStyle', '-');
	set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	plot_behav_data_on_top(min(summary_mat(valid_temp_idx, data_mat_columns.core_temp)),max(summary_mat(valid_temp_idx, data_mat_columns.core_temp)), dosage_levels, behav_mat, click_indices, infusion_indices, index_maps.behav);
	xlabel('Time(seconds)');
	grid on; set(gca, 'Layer', 'top');
end

file_name = sprintf('%s/subject_%s_summ_activity_temp', plot_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

%------------------------------------------------------------------------------
if isfield(data_mat_columns, 'HR_conf') & isfield(data_mat_columns, 'HR_var')
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	max_HR_conf = 110;
	subplot(2, 1, 1);
	[ax, h1, h2] = plotyy(index_maps.summary, summary_mat(:, data_mat_columns.HR_conf), index_maps.behav(vas_indices), behav_mat(vas_indices, 19)); hold on;
	set(get(ax(1), 'Ylabel'), 'String', 'HR confidence');
	set(get(ax(2), 'Ylabel'), 'String', 'VAS-Cocaine');
	set(ax(1), 'ylim', [0, max_HR_conf]);
	set(ax(2), 'ylim', [0, 10]);
	set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(h1, 'LineStyle', '-');
	set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	plot_behav_data_on_top(min(summary_mat(:, data_mat_columns.HR_conf)), max_HR_conf, dosage_levels,...
			behav_mat, click_indices, infusion_indices, index_maps.behav);
	xlabel('Time(seconds)');
	xlim([index_maps.time_axis(1), index_maps.time_axis(end)]);
	ylim([0, max_HR_conf]);
	grid on; set(gca, 'Layer', 'top');
	title(sprintf('Subject %s', strrep(subject_id, '_', '-')));

	valid_HR_var = summary_mat(:, data_mat_columns.HR_var) <= 280;
	subplot(2, 1, 2);
	[ax, h1, h2] = plotyy(index_maps.summary(valid_HR_var), summary_mat(valid_HR_var, data_mat_columns.HR_var), index_maps.behav(vas_indices), behav_mat(vas_indices, 14)); hold on;
	set(get(ax(1), 'Ylabel'), 'String', 'HR variability');
	set(get(ax(2), 'Ylabel'), 'String', 'VAS-Anxious');
	% set(ax(1), 'ylim', [0, 280]);
	set(ax(2), 'ylim', [0, 10]);
	set(ax(1), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(ax(2), 'xlim', [index_maps.time_axis(1), index_maps.time_axis(end)]);
	set(h1, 'LineStyle', '-');
	set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
	plot_behav_data_on_top(min(summary_mat(valid_HR_var, data_mat_columns.HR_var)),...
			max(summary_mat(valid_HR_var, data_mat_columns.HR_var)), dosage_levels, behav_mat,...
			click_indices, infusion_indices, index_maps.behav);
	xlim([index_maps.time_axis(1), index_maps.time_axis(end)]);
	xlabel('Time(seconds)');
	grid on; set(gca, 'Layer', 'top');

	file_name = sprintf('%s/subject_%s_summ_HR_conf_var', plot_dir, subject_id);
	savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));
end

%------------------------------------------------------------------------------
title_str = sprintf('Infusion events lined up for Subject %s\nNo. of infusions=%d', strrep(subject_id, '_', '-'), length(infusion_indices));

[common_indices, behav_idx, behav_summ_idx] = intersect(index_maps.behav(infusion_indices), index_maps.summary);
y_label_str = 'Heart rate';
file_name = sprintf('%s/subject_%s_infusion_hr', plot_dir, subject_id);
plot_event_window_length_data(data_mat_columns.HR, event_window_length, infusion_indices, summary_mat, index_maps.behav, behav_mat(:, 5), behav_summ_idx, y_label_str, 0, max_heart_rate, title_str, file_name);

y_label_str = 'Breathing rate';
file_name = sprintf('%s/subject_%s_infusion_br', plot_dir, subject_id);
plot_event_window_length_data(data_mat_columns.BR, event_window_length, infusion_indices, summary_mat, index_maps.behav, behav_mat(:, 5), behav_summ_idx, y_label_str, 0, max_breathing_rate, title_str, file_name);

y_label_str = 'ECG Amp';
file_name = sprintf('%s/subject_%s_infusion_ecg', plot_dir, subject_id);
plot_event_window_length_data(data_mat_columns.ECG_amp, event_window_length, infusion_indices, summary_mat, index_maps.behav, behav_mat(:, 5), behav_summ_idx, y_label_str, 0, 0.015, title_str, file_name);

if isfield(data_mat_columns, 'core_temp')
	y_label_str = 'Core body temp';
	file_name = sprintf('%s/subject_%s_infusion_temp', plot_dir, subject_id);
	plot_event_window_length_data(data_mat_columns.core_temp, event_window_length, infusion_indices, summary_mat, index_maps.behav, behav_mat(:, 5), behav_summ_idx, y_label_str, 36, 38, title_str, file_name);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_event_window_length_data(feature, event_window_length, event_indices, summary_mat, behav_indices, session_info, behav_summ_idx, y_label_str, ylim_min, ylim_max, title_str, file_name)

global image_format; global plot_dir;
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
event_window_length = event_window_length * 60;
[sessions, first_occur] = unique(session_info(event_indices), 'first');
session_event_counter = zeros(1, length(unique(session_info)));
acc_feature = [];

for i = 1:length(event_indices)
	event_window_length_data = summary_mat(behav_summ_idx(i)'-event_window_length:behav_summ_idx(i)'+event_window_length-1, feature);
	switch session_info(event_indices(i))
	case 1
		if any(find(event_indices(i) == event_indices(first_occur)))
			subplot(2, 2, 1), plot(event_window_length_data, 'r-', 'LineWidth', 2); hold on;
		else
			plot(event_window_length_data, 'b--');
		end
		session_event_counter(1) = session_event_counter(1) + 1;
	case 2
		if any(find(event_indices(i) == event_indices(first_occur)))
			subplot(2, 2, 2), plot(event_window_length_data, 'r-', 'LineWidth', 2); hold on;
		else
			plot(event_window_length_data, 'b--');
		end
		session_event_counter(2) = session_event_counter(2) + 1;
	case 3
		if any(find(event_indices(i) == event_indices(first_occur)))
			subplot(2, 2, 3), plot(event_window_length_data, 'r-', 'LineWidth', 2); hold on;
		else
			plot(event_window_length_data, 'b--');
		end
		session_event_counter(3) = session_event_counter(3) + 1;
	case 4
		if any(find(event_indices(i) == event_indices(first_occur)))
			subplot(2, 2, 4), plot(event_window_length_data, 'r-', 'LineWidth', 2); hold on;
		else
			plot(event_window_length_data, 'b--');
		end
		session_event_counter(4) = session_event_counter(4) + 1;
	otherwise, error('Invalid session information!');
	end

	acc_feature = [acc_feature; event_window_length_data'];
end

subplot(2, 2, 1);
plot(mean(acc_feature), 'k-', 'LineWidth', 2);
title(sprintf('session 1, %d events', session_event_counter(1)));
xlabel('Times(seconds)');
ylabel(y_label_str);
ylim([ylim_min, ylim_max]);
event_window_length_times = {'-5', '4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5'};
set(gca, 'XTick', 0:60:2*event_window_length, 'XTickLabel', event_window_length_times);
grid on; set(gca, 'Layer', 'top');

subplot(2, 2, 2);
plot(mean(acc_feature), 'k-', 'LineWidth', 2);
title(sprintf('session 2, %d events', session_event_counter(2)));
xlabel('Times(seconds)');
ylabel(y_label_str);
ylim([ylim_min, ylim_max]);
event_window_length_times = {'-5', '4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5'};
set(gca, 'XTick', 0:60:2*event_window_length, 'XTickLabel', event_window_length_times);
grid on; set(gca, 'Layer', 'top');

subplot(2, 2, 3);
plot(mean(acc_feature), 'k-', 'LineWidth', 2);
title(sprintf('session 3, %d events', session_event_counter(3)));
xlabel('Times(seconds)');
ylabel(y_label_str);
ylim([ylim_min, ylim_max]);
event_window_length_times = {'-5', '4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5'};
set(gca, 'XTick', 0:60:2*event_window_length, 'XTickLabel', event_window_length_times);
grid on; set(gca, 'Layer', 'top');

subplot(2, 2, 4);
plot(mean(acc_feature), 'k-', 'LineWidth', 2);
title(sprintf('session 4, %d events', session_event_counter(4)));
xlabel('Times(seconds)');
ylabel(y_label_str);
ylim([ylim_min, ylim_max]);
event_window_length_times = {'-5', '4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5'};
set(gca, 'XTick', 0:60:2*event_window_length, 'XTickLabel', event_window_length_times);
grid on; set(gca, 'Layer', 'top');

% title(title_str);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));
%}

