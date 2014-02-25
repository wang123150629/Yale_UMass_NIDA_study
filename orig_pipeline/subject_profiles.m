function[subject_profile] = subject_profiles(subject_id)

if nargin ~= 1, error('Missing subject id'); end

subject_profile = struct();
subject_profile.subject_id = sprintf('%s', subject_id);
subject_profile.columns = struct();

summ = struct();
summ.actual_hh = 4;
summ.actual_mm = 5;
summ.actual_ss = 6;
behav.actual_mm = 4;
summ.HR = 7;
summ.BR = 8;
summ.ECG_amp = 18;
summ.ECG_noise = 19;
summ.HR_conf = 20;
summ.HR_var = 21;
summ.activity = 11;
summ.peak_acc = 12;
summ.vertical = [26, 27];
summ.lateral = [28, 29];
summ.saggital = [30, 31];
summ.core_temp = 37;
summ.others = [1:6, 9:10, 13:17, 22:25, 32:36, 38:40];

behav = struct();
behav.actual_hh = 3;
behav.actual_mm = 4;
behav.session = 5;
behav.dosage = 6;
behav.click = 7;
behav.infusion = 8;
behav.vas_high = 9;
behav.vas_stim = 10;

raw_ecg = struct();
raw_ecg.actual_y = 1;
raw_ecg.actual_m = 2;
raw_ecg.actual_d = 3;
raw_ecg.actual_hh = 4;
raw_ecg.actual_mm = 5;
raw_ecg.actual_ss = 6;
raw_ecg.ecg = 7;

switch subject_id
case 'Malai_zephyr_drift_test'
	subject_profile.ylim = [-4.5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('central');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 1}.timestamp = sprintf('2013_11_04_16_24_33');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'central';
	subject_profile.events{1, 1}.exp_sessions = 1;
	subject_profile.events{1, 1}.dosage_levels = 0;
	subject_profile.events{1, 1}.start_time = [16, 24, 52];
	subject_profile.events{1, 1}.end_time = [16, 29, 52];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('right');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 2}.timestamp = sprintf('2013_11_04_16_24_33');
	subject_profile.events{1, 2}.rr_thresholds = 0.05;
	subject_profile.events{1, 2}.file_name = 'right';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [16, 30, 52];
	subject_profile.events{1, 2}.end_time = [16, 36, 1];
	subject_profile.events{1, 2}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('bottom');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_11_04_16_24_33');
	subject_profile.events{1, 3}.rr_thresholds = 0.05;
	subject_profile.events{1, 3}.file_name = 'bottom';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [16, 36, 33];
	subject_profile.events{1, 3}.end_time = [16, 42, 11];
	subject_profile.events{1, 3}.scaling_factor = 0.004882812500000;
case 'P20_036'
	subject_profile.ylim = [-3, 6];
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_05_30-10_13_20');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;
case 'P20_039'
	subject_profile.ylim = [-3, 6];
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_06_14-09_25_42');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:3;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;
case 'P20_040'
	subject_profile.ylim = [-4.5, 6];
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_06_27-09_21_36');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:3;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;
case 'P20_048'
	subject_profile.ylim = [-2, 0.5];
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_08_17-10_15_55');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;
case 'P20_058'
	subject_profile.ylim = [-2.5, 2];
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_11_02-08_37_47');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;
case 'P20_060'
	subject_profile.ylim = [-2, 2];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_12_13-06_52_45');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 2}.timestamp = sprintf('2012_12_17-03_04_46');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'exer';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [18, 00];
	subject_profile.events{1, 2}.end_time = [18, 15];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 2');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 3}.timestamp = sprintf('2012_12_11-03_08_16');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph2';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [11, 01];
	subject_profile.events{1, 3}.end_time = [12, 30];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;
case 'P20_061'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 1}.timestamp = sprintf('2013_01_18-00_01_01');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('activity');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_2');
	subject_profile.events{1, 2}.timestamp = sprintf('2013_01_11-08_55_25');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'acti';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	% subject normally exercised between 3 and 7pm. No exact days!
	% I am treating this data as other activity not necessarily exercise
	subject_profile.events{1, 2}.start_time = [15, 00];
	subject_profile.events{1, 2}.end_time = [19, 00];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	% Exercise session later in October as a followup session
	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('exercise');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_10_08-16_50_19');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'exer';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [16, 55];
	subject_profile.events{1, 3}.end_time = [17, 20];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;

	%{
	Really weird peak right after S wave and big trough after T wave. These peaks are always picked up as they are taller than
	T wave and deeper than Q wave making it impossible to find the 3 peak - 2 trough combination. This happens on the MPH day.
	Hence the low sample count

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 1');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_01_06-21_23_07');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [09, 52];
	subject_profile.events{1, 3}.end_time = [12, 22];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;
	%}

case 'P20_079'
	subject_profile.ylim = [-2, 2];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2013_06_11-07_23_15');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('bike');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 2}.timestamp = sprintf('2013_06_17-20_26_37');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'bike';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [09, 24];
	subject_profile.events{1, 2}.end_time = [09, 44];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 1');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_06_14-07_31_47');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [10, 52];
	subject_profile.events{1, 3}.end_time = [12, 22];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;

	%{
	Garbage, The raw ECG is all over the place between 0 and 5 mv. Constantly oscilating

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('bike2');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_2');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_06_18-09_49_30');
	subject_profile.events{1, 3}.rr_thresholds = 0.05;
	subject_profile.events{1, 3}.file_name = 'bike2';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [13, 00];
	subject_profile.events{1, 3}.end_time = [13, 50];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;
	%}

case 'P20_053'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 1}.timestamp = sprintf('2013_02_01-05_24_37');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0, 2:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 2}.timestamp = sprintf('2013_02_05-21_18_04');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'ping';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [21, 32];
	subject_profile.events{1, 2}.end_time = [21, 55];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 1');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_01_31-09_12_36');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [10, 55];
	subject_profile.events{1, 3}.end_time = [12, 25];
	subject_profile.events{1, 3}.scaling_factor = 0.004882812500000;

case 'P20_094'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 1}.timestamp = sprintf('2013_11_19-00_01_13');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 2}.timestamp = sprintf('2013_11_08-16_00_00');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'exer';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [15, 39];
	subject_profile.events{1, 2}.end_time = [15, 59];
	subject_profile.events{1, 2}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 2');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 3}.timestamp = sprintf('2013_11_14-09_00_00');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [11, 00];
	subject_profile.events{1, 3}.end_time = [12, 30];
	subject_profile.events{1, 3}.scaling_factor = 0.004882812500000;

	subject_profile.events{1, 4} = struct();
	subject_profile.events{1, 4}.label = sprintf('exercise 2');
	subject_profile.events{1, 4}.sensor = sprintf('Sensor_100');
	subject_profile.events{1, 4}.timestamp = sprintf('2013_11_11-12_30_00');
	subject_profile.events{1, 4}.rr_thresholds = 0.02;
	subject_profile.events{1, 4}.file_name = 'exer2';
	subject_profile.events{1, 4}.exp_sessions = 1;
	subject_profile.events{1, 4}.dosage_levels = 0;
	subject_profile.events{1, 4}.start_time = [13, 02];
	subject_profile.events{1, 4}.end_time = [13, 22];
	subject_profile.events{1, 4}.scaling_factor = 0.004882812500000;

case 'P20_098'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 1}.timestamp = sprintf('2014_01_10-07_39_55');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 2}.timestamp = sprintf('2014_01_08-14_44_50');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'exer';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [15, 08];
	subject_profile.events{1, 2}.end_time = [15, 28];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 2');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_5');
	subject_profile.events{1, 3}.timestamp = sprintf('2014_01_15-08_44_13');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [10, 51];
	subject_profile.events{1, 3}.end_time = [11, 21];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 4} = struct();
	subject_profile.events{1, 4}.label = sprintf('exercise 2');
	subject_profile.events{1, 4}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 4}.timestamp = sprintf('2014_01_13-14_12_32');
	subject_profile.events{1, 4}.rr_thresholds = 0.02;
	subject_profile.events{1, 4}.file_name = 'exer2';
	subject_profile.events{1, 4}.exp_sessions = 1;
	subject_profile.events{1, 4}.dosage_levels = 0;
	subject_profile.events{1, 4}.start_time = [15, 00];
	subject_profile.events{1, 4}.end_time = [15, 20];
	subject_profile.events{1, 4}.scaling_factor = 0.001220703125;

case 'P20_101'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	% Note this is Sensor 50 since I fused two files on January 24th to create this file. Missing 9 minutes of data in between
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_50');
	subject_profile.events{1, 1}.timestamp = sprintf('2014_01_24-08_08_22');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_2');
	subject_profile.events{1, 2}.timestamp = sprintf('2014_01_25-05_37_09');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'exer';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [11, 56];
	subject_profile.events{1, 2}.end_time = [12, 16];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 1');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_2');
	subject_profile.events{1, 3}.timestamp = sprintf('2014_01_16-08_08_39');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [10, 51];
	subject_profile.events{1, 3}.end_time = [11, 21];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;

case 'P20_103'
	subject_profile.ylim = [-5, 6];
	subject_profile.events = {};

	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 1}.timestamp = sprintf('2014_02_07-09_56_38');
	subject_profile.events{1, 1}.rr_thresholds = 0.02;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = [0:4];
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.events{1, 1}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 2} = struct();
	subject_profile.events{1, 2}.label = sprintf('exercise');
	subject_profile.events{1, 2}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 2}.timestamp = sprintf('2014_02_12-05_50_34');
	subject_profile.events{1, 2}.rr_thresholds = 0.02;
	subject_profile.events{1, 2}.file_name = 'exer';
	subject_profile.events{1, 2}.exp_sessions = 1;
	subject_profile.events{1, 2}.dosage_levels = 0;
	subject_profile.events{1, 2}.start_time = [09, 47];
	subject_profile.events{1, 2}.end_time = [10, 07];
	subject_profile.events{1, 2}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 3} = struct();
	subject_profile.events{1, 3}.label = sprintf('MPH day 2');
	subject_profile.events{1, 3}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 3}.timestamp = sprintf('2014_02_12-05_50_34');
	subject_profile.events{1, 3}.rr_thresholds = 0.02;
	subject_profile.events{1, 3}.file_name = 'mph';
	subject_profile.events{1, 3}.exp_sessions = 1;
	subject_profile.events{1, 3}.dosage_levels = 0;
	subject_profile.events{1, 3}.start_time = [12, 05];
	subject_profile.events{1, 3}.end_time = [13, 35];
	subject_profile.events{1, 3}.scaling_factor = 0.001220703125;

	subject_profile.events{1, 4} = struct();
	subject_profile.events{1, 4}.label = sprintf('exercise 2');
	subject_profile.events{1, 4}.sensor = sprintf('Sensor_3');
	subject_profile.events{1, 4}.timestamp = sprintf('2014_02_11-00_00_00');
	subject_profile.events{1, 4}.rr_thresholds = 0.02;
	subject_profile.events{1, 4}.file_name = 'exer2';
	subject_profile.events{1, 4}.exp_sessions = 1;
	subject_profile.events{1, 4}.dosage_levels = 0;
	subject_profile.events{1, 4}.start_time = [09, 20];
	subject_profile.events{1, 4}.end_time = [09, 40];
	subject_profile.events{1, 4}.scaling_factor = 0.001220703125;
otherwise
	error(sprintf('Invalid subject id=%s!', subject_id));
end

subject_profile.columns.summ = summ;
subject_profile.columns.behav = behav;
subject_profile.columns.raw_ecg = raw_ecg;
subject_profile.nEvents = length(subject_profile.events);

