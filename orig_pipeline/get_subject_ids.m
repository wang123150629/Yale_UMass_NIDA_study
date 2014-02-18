function [subject_ids] = get_subject_ids(number_of_subjects)

if nargin ~= 1, error('Missing number of subjects'); end

subject_ids = {'P20_036', 'P20_039', 'P20_040', 'P20_048', 'P20_058', 'P20_060', 'P20_061', 'P20_079', 'P20_053', 'P20_094',...
	       'P20_098', 'P20_101', 'P20_103'};

if number_of_subjects > length(subject_ids)
	error('Invalid number_of_subjects!');
else
	subject_ids = subject_ids(1, 1:number_of_subjects);
end

