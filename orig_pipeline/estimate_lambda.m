function[chosen_lambda] = estimate_labmda(subject_ids, test_subject_ids, classes_to_classify, feature_to_try,...
			  nRuns, classifier_to_try)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
nSubjects = numel(subject_ids);
% lambda = [0, 10, 10^2, 500, 10^3:10^3:10^4, 10^5, 10^6, 10^7, 10^8];
lambda = [0, 5, 10, 100, 1000, 10000];
nLambda = length(lambda);

mean_over_runs = NaN(nSubjects, nLambda);
errorbars_over_runs = NaN(nSubjects, nLambda);
tpr_over_runs = NaN(nSubjects, nLambda);
fpr_over_runs = NaN(nSubjects, nLambda);
auc_over_runs = NaN(nSubjects, nLambda);

for s = 1:nSubjects
	train_subjects = setdiff(1:nSubjects, s);
	test_subjects = [s];
	fprintf('\tfold=%d\n', s);
	fprintf('\ttrain subjects=[%s]\n', strtrim(sprintf('%d ', train_subjects)));
	fprintf('\ttest subjects=[%s]\n', strtrim(sprintf('%d ', test_subjects)));
	for l = 1:length(lambda)
		[mean_over_runs(s, l), errorbars_over_runs(s, l),...
		 tpr_over_runs(s, l), fpr_over_runs(s, l),...
		 auc_over_runs(s, l), feature_str,...
		 class_label, junk] = cross_validation_over_subjects({subject_ids{train_subjects}},...
				                          {subject_ids{test_subjects}}, classes_to_classify,...
							  feature_to_try, nRuns, classifier_to_try, lambda(l));
	end
end

mean_auc = mean(auc_over_runs);
l_interval = mean(auc_over_runs) - std(auc_over_runs)./sqrt(size(auc_over_runs, 1));
u_interval = mean(auc_over_runs) + std(auc_over_runs)./sqrt(size(auc_over_runs, 1));
[max_vals, max_idx] = max(mean_auc);
how_many_means_over_one_std = find(mean_auc >= l_interval(max_idx) & mean_auc <= u_interval(max_idx));

% Rule 1, 2, 3
if ~isempty(how_many_means_over_one_std)
	chosen_lambda = lambda(how_many_means_over_one_std(end));
	lambda_x_location = how_many_means_over_one_std(end);
else
	chosen_lambda = lambda(max_idx);
	lambda_x_location = max_idx;
end

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
plot(mean(auc_over_runs), 'b-', 'LineWidth', 2);
hold on; grid on;
color = [89, 89, 89] ./ 255; transparency = 0.4;
jbfill(1:size(auc_over_runs, 2), l_interval, u_interval, color, rand(1, 3), 0, transparency);
set(gca, 'XTick', 1:nLambda); set(gca, 'XTickLabel', lambda);
xlabel('Lambda'); ylabel('AUROC'); ylim([0, 1]); xlim([1, nLambda]);
plot(1:max_idx, repmat(max_vals, 1, length([1:max_idx])), 'k-', 'LineWidth', 2);
plot(repmat(max_idx, 1, length([l_interval(max_idx):0.01:max_vals])), l_interval(max_idx):0.01:max_vals, 'r-', 'LineWidth', 2);
plot(max_idx:nLambda, repmat(l_interval(max_idx), 1, length([max_idx:nLambda])), 'g-', 'LineWidth', 2);
plot(lambda_x_location, mean_auc(lambda_x_location), 'm*', 'MarkerSize', 10);
text(2, 0.05, sprintf('* chosen lambda=%0.4f', chosen_lambda), 'color', 'm', 'fontWeight', 'bold');
title(sprintf('Choice of lambda, %s vs %s, %s, %d fold cross validation', class_label{1}, class_label{2}, feature_str{1}, nSubjects));
file_name = sprintf('%s/%s/crossval_%dvs%d_lambda_feat%d', plot_dir, test_subject_ids{1},...
							classes_to_classify(1), classes_to_classify(2), feature_to_try);
savesamesize(gcf, 'file', file_name, 'format', image_format);

%{
resolution = 1e-4;
strech_auc = [mean_auc(max_idx):-resolution:mean_auc(max_idx+1)];
target_lambda_pos = find(round_to(strech_auc, 4) == round_to(l_interval(max_idx), 4));
if isempty(target_lambda_pos), target_lambda_pos = length(strech_auc); end
strech_lambda = linspace(lambda(max_idx), lambda(max_idx+1), length(strech_auc));
strech_xaxis = linspace(max_idx, max_idx+1, length(strech_auc));
chosen_lambda = strech_lambda(target_lambda_pos);
plot(strech_xaxis(target_lambda_pos), l_interval(max_idx), 'm*', 'MarkerSize', 10);
%}

