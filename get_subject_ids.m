function [subject_ids] = get_subject_ids(number_of_subjects)

if nargin ~= 1, error('Missing number of subjects'); end

switch number_of_subjects
case 1
	subject_ids = {'P20_040'};
case 2
	subject_ids = {'P20_040', 'P20_048'};
case 3
	subject_ids = {'P20_040', 'P20_048', 'P20_058'};
case 4
	subject_ids = {'P20_040', 'P20_048', 'P20_058', 'P20_060'};
case 5
	subject_ids = {'P20_040', 'P20_048', 'P20_058', 'P20_060', 'P20_061'};
case 6
	subject_ids = {'P20_040', 'P20_048', 'P20_058', 'P20_060', 'P20_061', 'P20_053'};
otherwise
	error('Invalid number of subjects!');
end
