function [feature_extracted_data, title_str] = setup_features(loaded_data, feature_set_flag)

feature_extracted_data = [];
title_str = '';

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
pt_peak_col = nInterpolatedFeatures + 2;
rt_peak_col = nInterpolatedFeatures + 3;
qt_peak_col = nInterpolatedFeatures + 4;
qtc_peak_col = nInterpolatedFeatures + 5;
pr_peak_col = nInterpolatedFeatures + 6;
p_height_col = nInterpolatedFeatures + 7;
q_height_col = nInterpolatedFeatures + 8;
r_height_col = nInterpolatedFeatures + 9;
s_height_col = nInterpolatedFeatures + 10;
t_height_col = nInterpolatedFeatures + 11;
dosage_col = nInterpolatedFeatures + 12;
expsess_col = nInterpolatedFeatures + 13;
label_col = nInterpolatedFeatures + 14;

switch feature_set_flag
case 1
	% Returning only the averaged (within windows) standardized features with labels
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'Std. feat';
case 2
	feature_extracted_data = loaded_data(:, rr_col);
	title_str = 'RR length';
case 3
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, rr_col)];
	title_str = 'std. feat+RR';
case 4
	feature_extracted_data = loaded_data(:, pt_peak_col);
	title_str = 'PT';
case 5
	feature_extracted_data = loaded_data(:, rt_peak_col);
	title_str = 'RT';
case 6
	feature_extracted_data = loaded_data(:, qt_peak_col);
	title_str = 'QT';
case 7
	feature_extracted_data = loaded_data(:, qtc_peak_col);
	title_str = 'QT_c';
case 8
	feature_extracted_data = loaded_data(:, pr_peak_col);
	title_str = 'PR';
case 9
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col)];
	title_str = 'All dist';
case 10
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, rr_col)];
	title_str = 'All dist+RR';
case 11
	feature_extracted_data = [loaded_data(:, p_height_col), loaded_data(:, q_height_col), loaded_data(:, r_height_col),...
				  loaded_data(:, s_height_col), loaded_data(:, t_height_col)];
	title_str = 'All heights';
case 12
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, p_height_col),...
				  loaded_data(:, q_height_col), loaded_data(:, r_height_col), loaded_data(:, s_height_col),...
				  loaded_data(:, t_height_col)];
	title_str = 'All dist+heights';
case 13
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, pt_peak_col),...
				  loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, p_height_col),...
				  loaded_data(:, q_height_col), loaded_data(:, r_height_col), loaded_data(:, s_height_col),...
				  loaded_data(:, t_height_col), loaded_data(:, rr_col)];
	title_str = 'All features';
otherwise
	error('Invalid feature set flag!');
end

feature_extracted_data = [feature_extracted_data, loaded_data(:, dosage_col), loaded_data(:, expsess_col), loaded_data(:, label_col)];
% disp(sprintf('%s', title_str));

