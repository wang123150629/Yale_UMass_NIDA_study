function[] = morph_func_hr()

close all;

nSubjects = 9;
set_of_features_to_try = [7];
subject_ids = get_subject_ids(nSubjects);
plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');
plot_str = {'r', 'r'; 'g', 'g'; 'b', 'b'};

% Looping over each subject and performing classification
for s = 6:nSubjects
	switch subject_ids{s}
	case 'P20_060', classes_to_classify = [5, 9, 11]; % dosage vs exercise and dosage vs MPH
	case 'P20_061', classes_to_classify = [5, 12]; % dosage vs activity
	case 'P20_079', classes_to_classify = [5, 13, 10]; % dosage vs bike and dosage vs MPH
	case 'P20_053', classes_to_classify = [5, 8, 10]; % dosage vs ping and dosage vs MPH
	end
	nAnalysis = length(classes_to_classify);
	class_label = {};
	% Looping over each pair of classification tasks i.e. 1 vs 2, 1 vs 3, etc
	figure('visible', 'on');
	set(gcf, 'Position', get_project_settings('figure_size'));

	for c = 1:nAnalysis
		[start_hr, mean_rt, std_rt, mean_th, std_th, class_label{c}] = classify_ecg_data(subject_ids{s},...
								classes_to_classify(c), set_of_features_to_try);
		subplot(1, 2, 1); errorbar(start_hr, mean_rt, std_rt, plot_str{c, 1}, 'LineWidth', 2);
		if c == 1; hold on; grid on; end
		h = plot(start_hr, mean_rt, sprintf('%so', plot_str{c, 1}), 'MarkerFaceColor', plot_str{c, 1}, 'MarkerSize', 6);
		hAnnotation = get(h, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('Heart Rate (bins)'); ylabel('RT distance'); xlim([48, 150]);

		subplot(1, 2, 2); errorbar(start_hr, mean_th, std_th, plot_str{c, 1}, 'LineWidth', 2);
		if c == 1; hold on; grid on; end
		h = plot(start_hr, mean_th, sprintf('%so', plot_str{c, 1}), 'MarkerFaceColor', plot_str{c, 1}, 'MarkerSize', 6);
		hAnnotation = get(h, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
		xlabel('Heart Rate (bins)'); ylabel('T wave height'); xlim([48, 150]);
	end
	title(sprintf('%s', get_project_settings('strrep_subj_id', subject_ids{s})));
	legend(class_label);
	file_name = sprintf('%s/%s/%s_morph_func_hr', plot_dir, subject_ids{s}, subject_ids{s});
	savesamesize(gcf, 'file', file_name, 'format', image_format);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[start_hr, mean_rt, std_rt, mean_th, std_th, class_label] = classify_ecg_data(subject_id, classes_to_classify,...
									set_of_features_to_try)

nBin_size = 5;
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
cut_off_heart_rate = (1000 ./ (cut_off_heart_rate .* 4)) .* 60;
assert(length(cut_off_heart_rate) == 2);
hr_bins = [cut_off_heart_rate(2):nBin_size:cut_off_heart_rate(1)] + 1;
hr_bins(1) = cut_off_heart_rate(2);

nFeatures = length(set_of_features_to_try);
loaded_data = [];
% Loop over each class in a two class problem and fetch the data instances x all features for each class (while respecting the session and dosage levels). Look at this as trimming the data matrix by only removing unnecessary rows
c = 1;
loaded_data = [loaded_data; massage_data(subject_id, classes_to_classify(c))];
class_information = classifier_profile(classes_to_classify(c));
class_label = class_information{1, 1}.label;

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
rr_col = nInterpolatedFeatures + 1;
rt_peak_col = nInterpolatedFeatures + 3;
t_height_col = nInterpolatedFeatures + 12;

% computing the heart rates from RR
hr_est = (1000 ./ (loaded_data(:, rr_col) .* 4)) .* 60;

start_hr = [];
mean_rt = [];
std_rt = [];
mean_th = [];
std_th = [];
for b = 1:length(hr_bins)-1
	bin_idx = find(hr_est >= hr_bins(b) & hr_est <= hr_bins(b+1)-1);
	if ~isempty(bin_idx)
		start_hr = [start_hr, hr_bins(b)];
		mean_rt = [mean_rt, mean(loaded_data(bin_idx, rt_peak_col))];
		std_rt = [std_rt, std(loaded_data(bin_idx, rt_peak_col))];
		mean_th = [mean_th, mean(loaded_data(bin_idx, t_height_col))];
		std_th = [std_th, std(loaded_data(bin_idx, t_height_col))];
	end
end

