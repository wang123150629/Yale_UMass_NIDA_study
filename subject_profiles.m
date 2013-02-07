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
raw_ecg.actual_hh = 4;
raw_ecg.actual_mm = 5;
raw_ecg.actual_ss = 6;
raw_ecg.ecg = 7;

switch subject_id
case 'P20_040'
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_06_27-09_21_36');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:3;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.ylim = [-4, 5];
case 'P20_048'
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_08_17-10_15_55');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.ylim = [-1, 0.5];
case 'P20_058'
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_11_02-08_37_47');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.ylim = [-2, 2];
case 'P20_060'
	subject_profile.events = cell(1, 1);
	subject_profile.events{1, 1} = struct();
	subject_profile.events{1, 1}.label = sprintf('cocaine');
	subject_profile.events{1, 1}.sensor = sprintf('Sensor_1');
	subject_profile.events{1, 1}.timestamp = sprintf('2012_12_13-06_52_45');
	subject_profile.events{1, 1}.rr_thresholds = 0.05;
	subject_profile.events{1, 1}.file_name = 'cocn';
	subject_profile.events{1, 1}.exp_sessions = 0:4;
	subject_profile.events{1, 1}.dosage_levels = [8, 16, 32, -3];
	subject_profile.ylim = [-2, 2];

	behav.actual_hh = 1;
	behav.actual_mm = 2;
	behav.session = 3;
	behav.dosage = 4;
	behav.click = 5;
	behav.infusion = 6;
	behav.vas_high = 7;
	behav.vas_stim = 8;
otherwise
	error(sprintf('Invalid subject id=%s!', subject_id));
end

subject_profile.columns.summ = summ;
subject_profile.columns.behav = behav;
subject_profile.columns.raw_ecg = raw_ecg;
subject_profile.nEvents = length(subject_profile.events);

%{
	subject_profile.events.mph1 = struct();
	subject_profile.events.mph1.label = sprintf('%s, mph1 day', subject_id);
	subject_profile.events.mph2 = struct();
	subject_profile.events.mph2.label = sprintf('%s, mph2 day', subject_id);
	subject_profile.events.exercise = struct();
	subject_profile.events.exercise.label = sprintf('%s, exercise session', subject_id);
	subject_profile.events.nighttime = struct();
	subject_profile.events.nighttime.label = sprintf('%s, nighttime activity', subject_id);
	subject_profile.events.others = struct();
%}
