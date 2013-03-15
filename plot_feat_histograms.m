function[] = plot_feat_histograms()

close all;

number_of_subjects = 6;
set_of_features_to_try = [9, 11];
feat_str = {{'PT dist', 'RT dist', 'QT dist' 'QT-c dist' 'PR dist'}, {'P height', 'Q depth', 'R height' 'S depth' 'T height'}};
classes_to_classify = [1, 2; 1, 3; 1, 4; 1, 5];
tr_percent = 60;

nAnalysis = size(classes_to_classify, 1);
subject_ids = get_subject_ids(number_of_subjects);

for s = 1:number_of_subjects
	train_subjects = setdiff(1:number_of_subjects, s);
	test_subjects = [s];
	fprintf('fold=%d\n', s);
	fprintf('train subjects=[%s]\n', strtrim(sprintf('%d ', train_subjects)));
	fprintf('test subjects=[%s]\n', strtrim(sprintf('%d ', test_subjects)));
	for c = 1:nAnalysis
		[train_set, test_set] = gather_train_test_data_relabel({subject_ids{1, train_subjects}},...
							{subject_ids{1, test_subjects}}, classes_to_classify(c, :));
		for f = 1:length(set_of_features_to_try)
			[cross_val_train_set, cross_val_test_set] =...
							trim_features(train_set, test_set, set_of_features_to_try(f));
			loaded_data = [];
			for cc = 1:length(classes_to_classify(c, :))
				loaded_data = [loaded_data; massage_data(subject_ids{s}, classes_to_classify(c, cc))];
			end
			[feature_extracted_data] = setup_features(loaded_data, set_of_features_to_try(f));
			[within_train_set, within_test_set] = partition_and_relabel(feature_extracted_data, tr_percent);

			assert(size(cross_val_test_set, 1) == size(within_train_set, 1)+size(within_test_set, 1));
			
			make_histograms(cross_val_train_set, cross_val_test_set, within_train_set, within_test_set,...
						subject_ids{s}, feat_str{f}, classes_to_classify(c, :));
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_histograms(cross_val_train_set, cross_val_test_set, within_train_set, within_test_set,...
							subject_id, feat_str, classes_to_classify)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
stddev = 3;

figure('visible', 'off'); set(gcf, 'Position', get_project_settings('figure_size'));
for f = 1:length(feat_str)
	all_instances = [cross_val_train_set(:, f)', cross_val_test_set(:, f)', within_train_set(:, f)', within_test_set(:, f)'];
	% x_lim = [min(all_instances), max(all_instances)];
	% x_lim = [mean(all_instances)-stddev*std(all_instances), mean(all_instances)+stddev*std(all_instances)];

	subplot(2, 5, f);
	hist(cross_val_train_set(:, f)); hold on;
	hist(cross_val_test_set(:, f));
	plot(mean(cross_val_train_set(:, f)), 1000, 'Marker', '*', 'Markersize', 5, 'color', 'r');
	plot(mean(cross_val_test_set(:, f)), 1000, 'Marker', '*', 'Markersize', 5, 'color', 'k');
	h = findobj(gca, 'type', 'patch');
	set(h(1), 'FaceColor', [166, 42, 42] ./ 255);
	set(h(2), 'FaceColor', [46, 139, 87] ./ 255);
	xlabel(sprintf('%s', feat_str{f})); ylabel ('Count');
	% xlim(x_lim);
	title(sprintf('%s - cross validation', get_project_settings('strrep_subj_id', subject_id)));

	subplot(2, 5, length(feat_str)+f);
	hist(within_train_set(:, f)); hold on;
	hist(within_test_set(:, f));
	plot(mean(within_train_set(:, f)), 100, 'Marker', '*', 'Markersize', 5, 'color', 'r');
	plot(mean(within_test_set(:, f)), 100, 'Marker', '*', 'Markersize', 5, 'color', 'k');
	h = findobj(gca, 'type', 'patch');
	set(h(1), 'FaceColor', [166, 42, 42] ./ 255);
	set(h(2), 'FaceColor', [46, 139, 87] ./ 255);
	xlabel(sprintf('%s', feat_str{f})); ylabel ('Count');
	% xlim(x_lim);
	title(sprintf('%s - within subject', get_project_settings('strrep_subj_id', subject_id)));
end
feat_file_name = strrep(lower(feat_str{f}), ' ', '_');
file_name = sprintf('%s/%s/hist_%s_%dvs%d', plot_dir, subject_id, feat_file_name, classes_to_classify(1), classes_to_classify(2));
savesamesize(gcf, 'file', file_name, 'format', image_format);

