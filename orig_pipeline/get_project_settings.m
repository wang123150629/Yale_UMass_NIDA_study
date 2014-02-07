function[out] = get_project_settings(request, varargin)

switch request
case 'plots'
	out = fullfile(pwd, 'plots');
case 'data'
	out = fullfile(pwd, 'ecg_data');
case 'results'
	out = fullfile(pwd, 'results');
case 'annotations'
	out = fullfile(pwd, 'ecgpuwave', 'annotations');
case 'log'
	out = fullfile(pwd, 'log');
case 'pdf_result_location'
	out = '/home/anataraj/NIH-craving/plots/paper_quality_plots';
case 'image_format'
	out = sprintf('-dpng');
case 'how_many_minutes_per_chunk'
	out = 5;
case 'font_size'
	% le_fs, xl_fs, yl_fs, xt_fs, yt_fs, tl_fs
	% out = [12, 15, 15, 12, 12, 15];
	out = [12, 20, 20, 12, 12, 20];
case 'how_many_sec_per_win'
	out = 30;
case 'how_many_sec_to_slide'
	out = 1;
case 'figure_size'
	out = [70, 10, 1300, 650];
case 'peak_thresholds'
	out = [0.1:0.05:0.9];
case 'how_many_std_dev'
	out = 3;
case 'raw_ecg_mat_time_res'
	out = 250;
case 'summ_mat_time_res'
	out = 60;
case 'clusters_apart'
	out = 100;
case 'magic_idx'
	assert(strcmp(varargin{1}, 'P20_040'));
	out = [1.29e+5:7.138e+5, 7.806e+5:3.4e+6, 3.515e+6:5945750];
case 'event_window_length'
	out = 5; % in minutes = 5 x 60 = 300 seconds
case 'strrep_subj_id'
	assert(length(varargin) == 1);
	out = strrep(varargin{1}, '_', '-');
case 'cut_off_heart_rate'
	out = [100, 300]; % timepoints i.e 100 x 4 = 400 milliseconds to 300 x 4 = 1200 milliseconds
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
otherwise, error('Invalid request!');
end
