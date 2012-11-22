function [subject_ids, subject_sessions] = get_subject_ids(number_of_subjects)

switch number_of_subjects
case 1
	% Only these two subjects have valid behavior data
	subject_ids = {'P20_048'};
	subject_sessions = {'2012_08_17-10_15_55'};
case 2
	% Only these two subjects have valid behavior data
	subject_ids = {'P20_040', 'P20_048'};
	subject_sessions = {'2012_06_27-09_21_36', '2012_08_17-10_15_55'};
case 3
	subject_ids = {'P20_036', 'P20_040', 'P20_048'};
	subject_sessions = {'2012_05_30-09_17_16', '2012_06_27-09_21_36', '2012_08_17-10_15_55'};
otherwise
	error('Invalid number of subjects!');
end
