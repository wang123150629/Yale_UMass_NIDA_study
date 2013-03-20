function[] = plot_pairwise_results(varargin)

close all;

if length(varargin) > 0
	paper_quality = varargin{1};
else
	paper_quality = false;
end

nSubjects = 6;
subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
temp = load(fullfile(result_dir, 'P20_036', sprintf('pairwise_1_vs_2_results.mat')));
nAnalysis = length(temp.auc_over_runs);
pairwise_auc = zeros(nSubjects, nSubjects, nAnalysis);

for s = 1:nSubjects
	train_subject = [s];
	other_subjects = setdiff(1:nSubjects, s);
	for o = 1:length(other_subjects)
		test_subject = [other_subjects(o)];
		classifier_results = load(fullfile(result_dir, subject_ids{s},...
				     sprintf('pairwise_%d_vs_%d_results.mat', train_subject, test_subject)));
		for a = 1:nAnalysis
			pairwise_auc(train_subject, test_subject, a) = classifier_results.auc_over_runs{a};
		end
	end
end

if paper_quality
	figure('visible', 'off'); 
	% figure(); 
	set(gcf, 'PaperPosition', [0 0 6 4]);
	set(gcf, 'PaperSize', [6 4]);
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
else
	figure();
	set(gcf, 'Position', get_project_settings('figure_size'));
end

for a = 1:size(pairwise_auc, 3)
	subplot(2, 2, a); imagesc(pairwise_auc(:, :, a));
	if paper_quality
		title(sprintf('AUC, std. feat, %s vs %s', temp.class_label{a}{1}, temp.class_label{a}{2}),...
							'FontSize', tl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		set(gca, 'XTickLabel', subject_ids, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
		set(gca, 'YTickLabel', subject_ids, 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');
		xlabel('Test subject', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
		ylabel('Train subject', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	else
		title(sprintf('AUC, std. feat, %s vs %s', temp.class_label{a}{1}, temp.class_label{a}{2}));
		set(gca, 'XTickLabel', subject_ids);
		set(gca, 'YTickLabel', subject_ids);
		xlabel('Test subject');
		ylabel('Train subject');
	end
end

if paper_quality
	plot_dir = get_project_settings('pdf_result_location');
	file_name = sprintf('%s/pairwise_auroc', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure
	%{	
	f = figure(); colormap jet; h = colorbar; c = get(f, 'children'); set(c(2), 'visible', 'off')
	set(gcf, 'PaperPosition', [0 0 2 4]);
	set(gcf, 'PaperSize', [2 4]);
	file_name = sprintf('%s/colorbar', plot_dir);
	saveas(gcf, file_name, 'pdf') % Save figure
	%}
else
	colorbar;
	file_name = sprintf('%s/pairwise_auroc', plot_dir);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

