function[] = craving_driver()

close all;

slide_or_chunk = 'slide';
peak_detect_appr = 4;
pqrst_flag = true;
number_of_subjects = 6;

subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');

for s = 6:number_of_subjects
	% create a subject profile
	if ~exist(fullfile(result_dir, subject_ids{s}, sprintf('subject_profile.mat')))
		subject_profile = subject_profiles(subject_ids{s});
	else
		subject_profile = load(fullfile(result_dir, subject_ids{s}, sprintf('subject_profile.mat')));
	end

	% pre-process the data and update the subject profile
	subject_profile = preprocess_ecg_data(subject_profile);

	% Create data samples from averaging over individual samples within a sliding or a blocked window
	switch slide_or_chunk
	case 'chunk'
		time_window = get_project_settings('how_many_minutes_per_chunk');
		% subject_profile = chunk_ecg_m_minutes(subject_profile);
	case 'slide'
		time_window = get_project_settings('how_many_sec_per_win');
		subject_profile = slide_ecg_k_seconds(subject_profile);
	otherwise, error('Invalid windowing strategy!');
	end
	
	subject_profile = detect_peaks(subject_profile, slide_or_chunk, time_window, peak_detect_appr, pqrst_flag);

	save(fullfile(result_dir, subject_ids{s}, sprintf('subject_profile')), '-struct', 'subject_profile');
	close all;
end

