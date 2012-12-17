function [subject_ids, subject_sessions, subject_thresholds] = get_subject_ids(number_of_subjects)

switch number_of_subjects
case 1
	% Only these two subjects have valid behavior data
	subject_ids = {'P20_058'};
	subject_sessions = {'2012_11_02-08_37_47'};
	subj_3_mat = [0.005, 0.05, 0.05, 0.005;...
		      0.005, 0.05, 0.05, 0.005;...
		      0.05, 0.05, 0.05, 0.005;...
		      0.02, 0.02, 0.02, 0.02;...
		      0.02, 0.02, 0.02, 0.02];
	subject_thresholds = {subj_3_mat};
case 2
	subject_ids = {'P20_040', 'P20_048'};
	subject_sessions = {'2012_06_27-09_21_36', '2012_08_17-10_15_55'};
	subject_thresholds = {repmat(0.05, 5, 4), repmat(0.05, 5, 4)};
case 3
	subject_ids = {'P20_040', 'P20_048', 'P20_058'};
	subject_sessions = {'2012_06_27-09_21_36', '2012_08_17-10_15_55', '2012_11_02-08_37_47'};
	subj_3_mat = [0.005, 0.05, 0.05, 0.005;...
		      0.005, 0.05, 0.05, 0.005;...
		      0.05, 0.05, 0.05, 0.005;...
		      0.02, 0.02, 0.02, 0.02;...
		      0.02, 0.02, 0.02, 0.02];
	subject_thresholds = {repmat(0.05, 5, 4), repmat(0.05, 5, 4), subj_3_mat};
otherwise
	error('Invalid number of subjects!');
end
