function[] = examine_weights()

close all;

number_of_subjects = 6;
feat_str = {'Std. feat', 'All distances', 'All distances+heights', 'All features'};
set_of_features_to_try = [1, 11, 14, 15];
classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
class_str = {'train baseline', 'train fixed 8mg', 'train fixed 16mg', 'train fixed 32mg', 'train all dosage'};

nAnalysis = size(classes_to_classify, 1);
subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

feat_2Ticks = 1:6;
feat2_xticks = {'pt', 'rt', 'qt', 'qt_c', 'pr', 'qs'};
feat_3Ticks = 1:11;
feat3_xticks = {'pt', 'rt', 'qt', 'qt_c', 'pr', 'qs', 'p', 'q', 'r', 's', 't'};

for s = 1:number_of_subjects
for a = 1:nAnalysis
for f = 1:length(set_of_features_to_try)
	unique_str = sprintf('%s_feat%d_%d_vs_%d', subject_ids{s}, set_of_features_to_try(f),...
							classes_to_classify(a, 1), classes_to_classify(a, 2));
	load(sprintf('%s/l2_betas/crossval_%s_weight_analysis.mat', result_dir, unique_str));
	betas = betas(2:end);

	figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
	% figure(); set(gcf, 'Position', get_project_settings('figure_size'));

	switch set_of_features_to_try(f)
	case 1
		plot(train_setm1, 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1, 'g-', 'LineWidth', 2);
		plot(exp(betas), 'r-', 'LineWidth', 3);
		legend(class_str{classes_to_classify(a, 1)}, class_str{classes_to_classify(a, 2)}, 'betas');
		title(sprintf('%s, %s, L2 log. reg weights', get_project_settings('strrep_subj_id', subject_ids{s}), feat_str{f}));
		xlabel('Features'); ylabel('std. millivolts');
	case 11
		target_idx = [1, 2, 3, 5, 6];
		subplot(1, 5, [1:4]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat2_xticks(target_idx)); 
		legend(class_str{classes_to_classify(a, 1)}, class_str{classes_to_classify(a, 2)}, 'betas');
		title(sprintf('%s, %s, L2 log. reg weights', get_project_settings('strrep_subj_id', subject_ids{s}), feat_str{f}));
		xlabel('Features'); ylabel('Distances');

		target_idx = [4];
		subplot(1, 5, 5);
		plot(train_setm1(1, target_idx), 'b*'); hold on; grid on;
		plot(train_set1(1, target_idx), 'g*');
		plot(exp(betas(1, target_idx)), 'r*');
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat2_xticks(target_idx)); 
		ylabel('Distances');
	case 14
		target_idx = [1:3, 5:6];
		subplot(1, 10, [1:4]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx)); 
		xlabel('Features'); ylabel('Distances');

		target_idx = [4];
		subplot(1, 10, 5);
		plot(train_setm1(1, target_idx), 'b*'); hold on; grid on;
		plot(train_set1(1, target_idx), 'g*');
		plot(exp(betas(1, target_idx)), 'r*');
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx)); 
		ylabel('Distances');

		target_idx = [7:11];
		subplot(1, 10, [6:10]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx)); 
		legend(class_str{classes_to_classify(a, 1)}, class_str{classes_to_classify(a, 2)}, 'betas');
		title(sprintf('%s, %s, L2 log. reg weights', get_project_settings('strrep_subj_id', subject_ids{s}), feat_str{f}));
		set(gca, 'YAxisLocation', 'right');
		xlabel('Features'); ylabel('Heights');
	case 15
		target_idx = [1:100];
		subplot(2, 11, [1:11]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		legend(class_str{classes_to_classify(a, 1)}, class_str{classes_to_classify(a, 2)}, 'betas');
		title(sprintf('%s, %s, L2 log. reg weights', get_project_settings('strrep_subj_id', subject_ids{s}), feat_str{f}));
		xlabel('Features'); ylabel('std. millivolts');

		target_idx = [101:103, 105:106];
		subplot(2, 11, [12:15]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx-100)); 
		xlabel('Features'); ylabel('Distances');

		target_idx = [104];
		subplot(2, 11, 16);
		plot(train_setm1(1, target_idx), 'b*'); hold on; grid on;
		plot(train_set1(1, target_idx), 'g*');
		plot(exp(betas(1, target_idx)), 'r*');
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx-100)); 
		ylabel('Distances');

		target_idx = [107:111];
		subplot(2, 11, [17:21]);
		plot(train_setm1(1, target_idx), 'b-', 'LineWidth', 2); hold on; grid on;
		plot(train_set1(1, target_idx), 'g-', 'LineWidth', 2);
		plot(exp(betas(1, target_idx)), 'r-', 'LineWidth', 3);
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', feat3_xticks(target_idx-100)); 
		set(gca, 'YAxisLocation', 'right');
		xlabel('Features'); ylabel('Heights');

		target_idx = [112];
		subplot(2, 11, [22]);
		plot(train_setm1(1, target_idx), 'b*'); hold on; grid on;
		plot(train_set1(1, target_idx), 'g*');
		plot(exp(betas(1, target_idx)), 'r*');
		set(gca, 'XTick', 1:length(target_idx));
		set(gca, 'XTickLabel', 'RR'); 
		set(gca, 'YAxisLocation', 'right');
		xlabel('Features'); ylabel('length');
	end
	unique_str = sprintf('%s_%d_vs_%d_weights_feat%d', subject_ids{s}, classes_to_classify(a, 1),...
				classes_to_classify(a, 2), set_of_features_to_try(f));
	file_name = sprintf('%s/%s/%s', plot_dir, subject_ids{s}, unique_str);
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end
end
close all;
end

