function[] = csv_for_abhinav()

number_of_subjects = 6;
result_dir = get_project_settings('results');
subject_id = get_subject_ids(number_of_subjects);

for s = 1:number_of_subjects
	mat1_path = fullfile(result_dir, subject_id{s}, sprintf('cocn_slide30_win.mat'));
	load(mat1_path);
	mat2_path = fullfile(result_dir, subject_id{s}, sprintf('cocn_temp.mat'));
	load(mat2_path);
	mat3_path = fullfile(result_dir, subject_id{s}, sprintf('cocn_pqrst_peaks_slide30.mat'));
	load(mat3_path);
	tmp = [hold_mat_temp_all, infusion_presence, click_presence, p_point, q_point, r_point, s_point, t_point,...
		pqrst_mat(:, [1:101, 107:108])];
	csvwrite(fullfile(result_dir, subject_id{s}, sprintf('%s_timestamp_features.csv', subject_id{s})), tmp);
end

