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
qs_peak_col = nInterpolatedFeatures + 7;
p_height_col = nInterpolatedFeatures + 8;
q_height_col = nInterpolatedFeatures + 9;
r_height_col = nInterpolatedFeatures + 10;
s_height_col = nInterpolatedFeatures + 11;
t_height_col = nInterpolatedFeatures + 12;
dosage_col = nInterpolatedFeatures + 13;
expsess_col = nInterpolatedFeatures + 14;
label_col = nInterpolatedFeatures + 15;
cols_to_scale = '';

switch feature_set_flag
case 1
	feature_extracted_data = loaded_data(:, rr_col);
	title_str = 'RR';
case 2
	feature_extracted_data = loaded_data(:, qs_peak_col);
	title_str = 'QS';
case 3
	feature_extracted_data = loaded_data(:, pr_peak_col);
	title_str = 'PR';
case 4
	feature_extracted_data = loaded_data(:, qt_peak_col);
	title_str = 'QT';
case 5
	feature_extracted_data = loaded_data(:, qtc_peak_col);
	title_str = 'QTc';
case 6
	feature_extracted_data = loaded_data(:, t_height_col);
	title_str = 'T';
case 7
	feature_extracted_data = [loaded_data(:, qs_peak_col), loaded_data(:, pr_peak_col),...
				  loaded_data(:, qt_peak_col), loaded_data(:, qtc_peak_col),...
				  loaded_data(:, t_height_col)];
	title_str = 'AM';
	cols_to_scale = 1:4;
case 8
	feature_extracted_data = [loaded_data(:, qs_peak_col), loaded_data(:, pr_peak_col),...
				  loaded_data(:, qt_peak_col), loaded_data(:, qtc_peak_col)];
	title_str = 'AM-T';
	cols_to_scale = 4;
case 9
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'W';
case 10
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, qs_peak_col),...
				  loaded_data(:, pr_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, t_height_col)];
	title_str = 'AM+W';
	cols_to_scale = 101:104;
otherwise
	error('Invalid feature set flag!');
end

if ~isempty(cols_to_scale)
	feature_extracted_data = scale_features(feature_extracted_data, cols_to_scale);
end

feature_extracted_data = [feature_extracted_data, loaded_data(:, dosage_col), loaded_data(:, expsess_col), loaded_data(:, label_col)];
% disp(sprintf('%s', title_str));

%{
switch feature_set_flag
case 1
	% Returning only the averaged (within windows) standardized features with labels
	feature_extracted_data = loaded_data(:, ecg_col);
	title_str = 'W';
case 2
	feature_extracted_data = loaded_data(:, rr_col);
	title_str = 'RR';
case 3
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, rr_col)];
	title_str = 'std. feat+RR';
	cols_to_scale = size(feature_extracted_data, 2);
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
	feature_extracted_data = loaded_data(:, qs_peak_col);
	title_str = 'QS';
case 10
	feature_extracted_data = [loaded_data(:, qtc_peak_col), loaded_data(:, t_height_col)];
	title_str = 'QTc+T';
	cols_to_scale = 1;
case 11
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, qs_peak_col)];
	title_str = 'Dist';
	cols_to_scale = [4];
case 12
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, qs_peak_col),...
				  loaded_data(:, rr_col)];
	title_str = 'Dist+RR';
	cols_to_scale = [4, 7];
case 13
	feature_extracted_data = [loaded_data(:, p_height_col), loaded_data(:, q_height_col), loaded_data(:, r_height_col),...
				  loaded_data(:, s_height_col), loaded_data(:, t_height_col)];
	title_str = 'Hgts';
case 14
	feature_extracted_data = [loaded_data(:, pt_peak_col), loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, qs_peak_col),...
				  loaded_data(:, p_height_col), loaded_data(:, q_height_col), loaded_data(:, r_height_col),...
				  loaded_data(:, s_height_col), loaded_data(:, t_height_col)];
	title_str = 'Dist+hgts';
	cols_to_scale = 1:6;
case 15
	feature_extracted_data = [loaded_data(:, ecg_col), loaded_data(:, pt_peak_col),...
				  loaded_data(:, rt_peak_col), loaded_data(:, qt_peak_col),...
				  loaded_data(:, qtc_peak_col), loaded_data(:, pr_peak_col), loaded_data(:, qs_peak_col),...
				  loaded_data(:, p_height_col), loaded_data(:, q_height_col), loaded_data(:, r_height_col),...
				  loaded_data(:, s_height_col), loaded_data(:, t_height_col), loaded_data(:, rr_col)];
	title_str = 'All feat';
	cols_to_scale = [101:106, size(feature_extracted_data, 2)];
otherwise
	error('Invalid feature set flag!');
end
%}

