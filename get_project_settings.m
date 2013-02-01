function[out] = get_project_settings(request, varargin)

switch request
case 'plots'
	out = fullfile(pwd, 'plots');
case 'data'
	out = fullfile(pwd, 'data');
case 'results'
	out = fullfile(pwd, 'results');
case 'image_format'
	out = sprintf('-dpng');
case 'how_many_minutes_per_chunk'
	out = 5;
case 'how_many_sec_per_win'
	out = 30;
case 'how_many_std_dev'
	out = 3;
case 'exp_sessions'
	out = 0:4;
case 'summ_mat_time_res'
	out = 60;
case 'event_window_length'
	out = 5; % in minutes = 5 x 60 = 300 seconds
case 'dosage_levels'
	out = [8, 16, 32, -3];
case 'strrep_subj_id'
	assert(length(varargin) == 1);
	out = strrep(varargin{1}, '_', '-');
case 'vas_measures'
	out = [9, 10]; % corresponding to VAS high and VAS stimulating
case 'cut_off_heart_rate'
	out = [100, 300]; % i.e 100 x 4 = 400 milliseconds to 300 x 4 = 1200 milliseconds
case 'nInterpolatedFeatures'
	out = get_project_settings('cut_off_heart_rate');
	out = out(1);
case 'peak_det'
	assert(length(varargin) == 1);
	switch varargin{1}
	case 1, out = 'no-checks';
	case 2, out = 'mean-whole-signal';
	case 3, out = 'mean-first-last';
	case 4, out = 'strict-3-2';
	otherwise, error('Invalid peak detection technique');
	end
case 'data_mat_columns',
	out = struct();
	out.HR = 7;
	out.BR = 8;
	out.ECG_amp = 18;
	out.ECG_noise = 19;
	out.HR_conf = 20;
	out.HR_var = 21;
	out.activity = 11;
	out.peak_acc = 12;
	out.vertical = [26, 27];
	out.lateral = [28, 29];
	out.saggital = [30, 31];
	out.core_temp = 37;
	out.others = [1:6, 9:10, 13:17, 22:25, 32:36, 38:40];
otherwise, error('Invalid request!');
end
