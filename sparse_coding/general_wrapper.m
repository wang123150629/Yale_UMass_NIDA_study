function[] = general_wrapper()

% general_wrapper()

plot_dir = get_project_settings('plots');

%{
sparse_coding_wrapper('140210a', 13);
sparse_coding_wrapper('140210b', 14);
sparse_coding_wrapper('140210c', 15);
sparse_coding_wrapper('140210d', 16);
sparse_coding_wrapper('140210e', 17);
sparse_coding_wrapper('140210f', 18);
sparse_coding_wrapper('140210g', 19);
sparse_coding_wrapper('140210h', 20);
sparse_coding_wrapper('140210i', 21);
%}

matching_pm = 1:10;
pipeline = 17;
analysis_id = '140210z';
for m = 1:length(matching_pm)
	[mul_confusion_mat{m}, matching_confusion_mat{m}, crf_confusion_mat{m}] =...
			sparse_coding_wrapper(analysis_id, pipeline, 1, matching_pm(m));
end
results = struct();
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.matching_pm = matching_pm;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

runs = 1:10;
matching_pm = 4;
pipeline = 17;
analysis_id = '140210y';
for r = 1:length(runs)
	[mul_confusion_mat{r}, matching_confusion_mat{r}, crf_confusion_mat{r}] =...
			sparse_coding_wrapper(analysis_id, pipeline, 1, matching_pm);
end
results = struct();
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.runs = runs;
results.matching_pm = matching_pm;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

runs = 1:10;
matching_pm = 4;
pipeline = 17;
analysis_id = '140210x';
for r = 1:length(runs)
	[mul_confusion_mat{r}, matching_confusion_mat{r}, crf_confusion_mat{r}] =...
			sparse_coding_wrapper(analysis_id, pipeline, 2, matching_pm);
end
results = struct();
results.mul_confusion_mat = mul_confusion_mat;
results.matching_confusion_mat = matching_confusion_mat;
results.crf_confusion_mat = crf_confusion_mat;
results.runs = runs;
results.matching_pm = matching_pm;
save(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id), '-struct', 'results');

