function[] = craving_driver()

result_dir = get_project_settings('results');

number_of_subjects = 3;
[subject_id, subject_session, subject_threshold] = get_subject_ids(number_of_subjects);

for s = 1:number_of_subjects
	if ~exist(fullfile(result_dir, subject_id{s}, sprintf('preprocessed_data.mat')))
		preprocessed_data = preprocess_ecg_data(subject_id{s}, subject_session{s}, subject_threshold{s});
	else
		load(fullfile(result_dir, subject_id{s}, sprintf('preprocessed_data.mat')));
	end
	
	if ~exist(fullfile(result_dir, subject_id{s}, sprintf('ten_min_chunks.mat')))
		chunk_ecg_ten_minutes(preprocessed_data, subject_id{s});
	end
	close all;
end

