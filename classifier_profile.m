function[class_information] = classifier_profile(what_to_classify)

class_information = cell(1, 1);
switch what_to_classify
case 1
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0;
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'base';
case 2
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1;
	class_information{1, 1}.dosage = 8;
	class_information{1, 1}.label = 'fix 8mg';
case 3
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1;
	class_information{1, 1}.dosage = 16;
	class_information{1, 1}.label = 'fix 16mg';
case 4
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1;
	class_information{1, 1}.dosage = 32;
	class_information{1, 1}.label = 'fix 32mg';
case 5
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1:4; % 1, 2, 3, 4
	class_information{1, 1}.dosage = [-3, 8, 16, 32];
	class_information{1, 1}.label = 'dosage';
case 9
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'exer';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'exercise';
case 10
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'mph2';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'MPH day 2';
case 12
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'acti';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'Activity';
%{
case 6
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0:4; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'all sess baseline';
case 8
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1:4; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'b/w sess baseline';
case 11
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'hab';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'Habituation day';
%}

otherwise
	error('Invalid case!');
end

