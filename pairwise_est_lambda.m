function[chosen_lambda] = pairwise_est_lambda(complete_train_set, train_subject_ids, test_subject_ids, classes_to_classify,...
			  feature_to_try, nRuns, classifier_to_try, class_label, chance_baseline)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
% lambda = [0, 10, 10^2, 500, 10^3:10^3:10^4, 10^5, 10^6, 10^7, 10^8];
lambda = [0, 5, 10, 100, 1000, 10000];
nLambda = length(lambda);
nPartitions = 5;
auc_over_runs = NaN(nPartitions, nLambda);

cat1 = find(complete_train_set(:, end) > 0);
tmp = 1:round_to(length(cat1) / nPartitions, 0):length(cat1);
if length(tmp) > nPartitions, tmp = tmp(1:end-1); end
part_start_end(:, 1) = cat1(tmp);

tmp = [round_to(length(cat1) / nPartitions, 0):round_to(length(cat1) / nPartitions, 0):length(cat1), length(cat1)];
if length(tmp) > nPartitions, tmp = tmp([1:end-2, end]); end
part_start_end(:, 2) = cat1(tmp);

catm1 = find(complete_train_set(:, end) < 0);
tmp = 1:round_to(length(catm1) / nPartitions, 0):length(catm1);
if length(tmp) > nPartitions, tmp = tmp(1:end-1); end
part_start_end(:, 3) = catm1(tmp);

tmp = [round_to(length(catm1) / nPartitions, 0):round_to(length(catm1) / nPartitions, 0):length(catm1), length(catm1)];
if length(tmp) > nPartitions, tmp = tmp([1:end-2, end]); end
part_start_end(:, 4) = catm1(tmp);

for p = 1:nPartitions
	part_test_idx = [part_start_end(p, 1):part_start_end(p, 2), part_start_end(p, 3):part_start_end(p, 4)];
	part_train_idx = setdiff(1:size(complete_train_set, 1), part_test_idx);
	assert(isempty(intersect(part_train_idx, part_test_idx)));
	assert(length(part_train_idx) + length(part_test_idx) == size(complete_train_set, 1));
	fprintf('\tfold=%d\n', p);
	for l = 1:length(lambda)
		[junk, junk, junk, junk,...
		 auc_over_runs(p, l), feature_str,...
		 class_label, junk] = pairwise_cross_val({}, {}, classes_to_classify, feature_to_try,...
				      nRuns, classifier_to_try, lambda(l), complete_train_set(part_train_idx, :),...
				      complete_train_set(part_test_idx, :), class_label, chance_baseline);
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
title(sprintf('Choice of lambda, %s vs %s, %s, %d fold cross validation', class_label{1}, class_label{2}, feature_str{1}, nPartitions));
file_name = sprintf('%s/%s/pairwise_%s_vs_%s_%dvs%d_lambda_feat%d', plot_dir, test_subject_ids{1},...
		train_subject_ids{1}, test_subject_ids{1}, classes_to_classify(1), classes_to_classify(2), feature_to_try);
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

