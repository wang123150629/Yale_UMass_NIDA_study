function[class_information] = classifier_profile(what_to_classify)

class_information = cell(1, 1);
switch what_to_classify
case 1
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'baseline';
case 2
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 8;
	class_information{1, 1}.label = 'fixed 8mg';
case 3
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 16;
	class_information{1, 1}.label = 'fixed 16mg';
case 4
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 32;
	class_information{1, 1}.label = 'fixed 32mg';
case 5
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0:4; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'all sess baseline';
case 6
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0:4; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = [8, 16, 32];
	class_information{1, 1}.label = '8mg, 16mg, 32mg';
case 7
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 0; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'initial baseline';
case 8
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'cocn';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1:4; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = -3;
	class_information{1, 1}.label = 'b/w sess baseline';
case 9
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'exer';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'exer sess';
case 10
	class_information{1, 1} = struct();
	class_information{1, 1}.event = 'mph1';
	class_information{1, 1}.slide_or_chunk = 'slide';
	class_information{1, 1}.pqrst_flag = true;
	class_information{1, 1}.time_window = 30;
	class_information{1, 1}.exp_session = 1; % 0, 1, 2, 3, 4
	class_information{1, 1}.dosage = 0;
	class_information{1, 1}.label = 'MPH day 1';
otherwise
	error('Invalid case!');
end

