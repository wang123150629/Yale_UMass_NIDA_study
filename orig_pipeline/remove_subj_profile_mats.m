function[] = remove_subj_profile_mats(subject_id)

result_dir = get_project_settings('results');
subject_profile = load(fullfile(result_dir, subject_id, sprintf('subject_profile.mat')));
orig_subject_profile = subject_profiles(subject_id);

for d = 1:length(subject_profile.events)
	fprintf('%s\n', subject_profile.events{d}.label);
end

for e = 1:orig_subject_profile.nEvents
	fprintf('%s\n', orig_subject_profile.events{e}.label);
end
event_to_add = input('Enter event to add... ');

subject_profile.events{d+1} = orig_subject_profile.events{event_to_add};

keyboard

save(fullfile(result_dir, subject_id, sprintf('subject_profile')), '-struct', 'subject_profile');

%{
for e = 1:subject_profile.nEvents
	fprintf('%s\n', subject_profile.events{e}.label);
end
event_to_kill = input('Enter event to remove... ');
subject_profile.events = subject_profile.events(1, setdiff(1:subject_profile.nEvents, event_to_kill));
%}

