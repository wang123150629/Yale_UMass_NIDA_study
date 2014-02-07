function[] = general_wrapper()

% general_wrapper()

sparse_coding_wrapper('140204d', 16);
sparse_coding_wrapper('140204e', 17);
sparse_coding_wrapper('140204f', 18);

keyboard

matching_pm = 1:10;
for m = 1:length(matching_pm)
	[mul_confusion_mat{m}, matching_confusion_mat{m}, crf_confusion_mat{m}] =...
			sparse_coding_wrapper(analysis_id, pipeline, 1, matching_pm(m));
end

