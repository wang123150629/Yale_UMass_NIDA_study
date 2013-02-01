function[] = craving_driver()

chunk_or_slide = 'slide';

number_of_subjects = 3;
[subject_id, subject_session, subject_threshold] = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');

for s = 1:number_of_subjects
	if ~exist(fullfile(result_dir, subject_id{s}, sprintf('preprocessed_data.mat')))
		preprocessed_data = preprocess_ecg_data(subject_id{s}, subject_session{s}, subject_threshold{s});
	else
		load(fullfile(result_dir, subject_id{s}, sprintf('preprocessed_data.mat')));
	end

	switch chunk_or_slide
	case 'chunk'
		how_many_minutes_per_chunk = get_project_settings('how_many_minutes_per_chunk');
		if ~exist(fullfile(result_dir, subject_id{s}, sprintf('chunks_%d_min.mat', how_many_minutes_per_chunk)))
			chunk_ecg_m_minutes(preprocessed_data, subject_id{s});
		end
	case 'slide'
		how_many_sec_per_win = get_project_settings('how_many_sec_per_win');
		if ~exist(fullfile(result_dir, subject_id{s}, sprintf('sliding_%dsec_win', how_many_sec_per_win)))
			sliding_window_ecg(preprocessed_data, subject_id{s});
		end
	otherwise, error('Invlid windowing strategy!');
	end

	close all;
end

