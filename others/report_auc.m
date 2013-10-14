function[] = report_auc()

tr_percent = 60;
nSubjects = 7;
target_subjects = [6, 7];
subject_analyses = {[5, 6], [4]};

subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
target_feat_rows = 1:15;
target_ana_cols = 1:4;
auroc_over_subjects = NaN(length(target_feat_rows), length(target_ana_cols), nSubjects);

temp = [];
for s = 1:length(target_subjects)
	classifier_results = load(fullfile(result_dir, subject_ids{target_subjects(s)},...
							sprintf('classifier_results_tr%d.mat', tr_percent)));
	nAnalysis = length(subject_analyses{s});
	for a = 1:nAnalysis
		temp = [temp, classifier_results.auc_over_runs{subject_analyses{s}(a)}];
	end
end

write_mat_out(temp, true);

keyboard

