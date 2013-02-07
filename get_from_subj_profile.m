function[out] = get_from_subj_profile(subject_id, event, query)

result_dir = get_project_settings('results');
subject_profile = load(fullfile(result_dir, subject_id, 'subject_profile.mat'));

out = '';
for e = 1:length(subject_profile.events)
	if strcmp(subject_profile.events{1, e}.file_name, event)
		switch query
		case 'dosage_levels'
			out = subject_profile.events{1, e}.dosage_levels;
		end
	end
end

