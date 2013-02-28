function[loaded_data] = massage_data(subject_id, class_label)

result_dir = get_project_settings('results');
class_information = classifier_profile(class_label);
event = class_information{1, 1}.event;
pqrst_flag = class_information{1, 1}.pqrst_flag;
time_window = class_information{1, 1}.time_window;
slide_or_chunk = class_information{1, 1}.slide_or_chunk; 
target_dosage = class_information{1, 1}.dosage;
target_exp_sess = class_information{1, 1}.exp_session;

peaks_data = load(fullfile(result_dir, subject_id, sprintf('%s_pqrst_peaks_%s%d.mat', event, slide_or_chunk, time_window)));
window_data = load(fullfile(result_dir, subject_id, sprintf('%s_%s%d_win.mat', event, slide_or_chunk, time_window)));
if pqrst_flag
	window_data = window_data.pqrst_mat;
else
	window_data = window_data.rr_mat;
end

assert(size(window_data, 1) == size(peaks_data.p_point, 1));
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
rr_length_col = nInterpolatedFeatures + 1;
dos_col = size(window_data, 2) - 1;
exp_sess_col = size(window_data, 2);

loaded_data = [window_data(:, 1:rr_length_col), (peaks_data.t_point(:, 1) - peaks_data.p_point(:, 1))];
loaded_data = [loaded_data, (peaks_data.t_point(:, 1) - peaks_data.r_point(:, 1))];
loaded_data = [loaded_data, (peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1))];
loaded_data = [loaded_data, ((peaks_data.t_point(:, 1) - peaks_data.q_point(:, 1)) .* sqrt(window_data(:, rr_length_col)))];
loaded_data = [loaded_data, (peaks_data.r_point(:, 1) - peaks_data.p_point(:, 1))];
loaded_data = [loaded_data, peaks_data.p_point(:, 2)];
loaded_data = [loaded_data, peaks_data.q_point(:, 2)];
loaded_data = [loaded_data, peaks_data.r_point(:, 2)];
loaded_data = [loaded_data, peaks_data.s_point(:, 2)];
loaded_data = [loaded_data, peaks_data.t_point(:, 2)];

temp_dosage_mat = NaN(size(loaded_data, 1), length(target_dosage));
for d = 1:length(target_dosage)
	temp_dosage_mat(:, d) = window_data(:, dos_col) == target_dosage(d);
end
temp_exp_sess_mat = NaN(size(loaded_data, 1), length(target_dosage));
for e = 1:length(target_exp_sess)
	temp_exp_sess_mat(:, e) = window_data(:, exp_sess_col) == target_exp_sess(e);
end

target_samples = find(peaks_data.q_point(:, 1) > 0 & sum(temp_dosage_mat, 2) & sum(temp_exp_sess_mat, 2));
loaded_data = [loaded_data(target_samples, :), window_data(target_samples, dos_col),...
	       window_data(target_samples, exp_sess_col), repmat(class_label, length(target_samples), 1)];

