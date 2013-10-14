function[] = feature_heat_maps()

% This code is a clone of classify_ecg_driver(60)

nSubjects = 9;
set_of_features_to_try = [1:6];
tr_percent = 60;
partitioning_style = 2;

subject_ids = get_subject_ids(nSubjects);
result_dir = get_project_settings('results');

% Looping over each subject and performing classification
for s = 6:nSubjects
	classes_to_classify = [1:5];
	switch subject_ids{s}
	case 'P20_053', classes_to_classify = [1, 5, 8, 10];
	case 'P20_060', classes_to_classify = [classes_to_classify, 9, 11];
	case 'P20_061', classes_to_classify = [classes_to_classify(2:end, :), 12, 10];
	case 'P20_079', classes_to_classify = [classes_to_classify, 13, 14, 10];
	end

	nClasses = length(classes_to_classify);
	loaded_data = [];
	for c = 1:nClasses
		loaded_data = [loaded_data; massage_data(subject_ids{s}, classes_to_classify(c))];
		class_information = classifier_profile(classes_to_classify(c));
		class_label{1, c} = class_information{1, 1}.label;
	end
	labels = unique(loaded_data(:, end));

	for f = 1:length(set_of_features_to_try)
		[feature_extracted_data, feature_str{1, f}] = setup_features(loaded_data, set_of_features_to_try(f));

		complete_train_set = [];
		complete_test_set = [];
		for c = 1:length(labels)
			[train_set, test_set] = fetch_training_instances(labels(c), feature_extracted_data, tr_percent, partitioning_style);
			complete_train_set = [complete_train_set; train_set];
			complete_test_set = [complete_test_set; test_set];
		end
		assert(isequal(size(feature_extracted_data, 1), size(complete_test_set, 1) + size(complete_train_set, 1)));
		make_heat_maps(complete_train_set, complete_test_set, class_label, feature_str{1, f}, subject_ids{s}, f);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = make_heat_maps(complete_train_set, complete_test_set, class_label, feature_str, subject_id, f)

nBins = 25;
image_format = get_project_settings('image_format');
plot_dir = get_project_settings('plots');
assert(size(complete_train_set, 2) == 2);

f = figure('visible', 'off');
set(gcf, 'Position', [70, 10, 1300, 650]);

min_feat = min([complete_train_set(:, 1); complete_test_set(:, 1)]);
max_feat = max([complete_train_set(:, 1); complete_test_set(:, 1)]);
xvalues = linspace(min_feat, max_feat, nBins);
labels = unique(complete_train_set(:, end));

train_heat_map = NaN(length(labels), length(xvalues));
test_heat_map = NaN(length(labels), length(xvalues));
for l = 1:length(labels)
	train_idx = find(complete_train_set(:, end) == labels(l));
	[nelements, centers] = hist(complete_train_set(train_idx, 1), xvalues);
	train_heat_map(l, :) = nelements ./ sum(nelements);

	test_idx = find(complete_test_set(:, end) == labels(l));
	[nelements, centers] = hist(complete_test_set(test_idx, 1), xvalues);
	test_heat_map(l, :) = nelements ./ sum(nelements);
	
	subplot(4, 2, l); imagesc([train_heat_map(l, :); test_heat_map(l, :)]);
	h = colorbar;
	set(h, 'ylim', [0, 1]);
	title(class_label{1, l});
	xlabel('Bins');
	ylabel('Test - Train');
	set(gca, 'YTickLabel', '');
end
mtit(f, sprintf('%s, %s', get_project_settings('strrep_subj_id', subject_id), feature_str),...
				'fontsize', 15, 'color', [1 0 0], 'xoff', 1300/1250000, 'yoff', .025);
set(f, 'visible', 'off');

file_name = sprintf('%s/feature_heatmaps/%s_feat_%d', plot_dir, subject_id, f);
savesamesize(gcf, 'file', file_name, 'format', image_format);

