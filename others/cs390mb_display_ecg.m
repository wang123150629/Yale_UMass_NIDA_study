function[] = cs390mb_display_ecg(option)

close all;
plot_dir = get_project_settings('plots');

global ecg_mat
global peak_labels
global time_matrix
global show_r_peaks
show_r_peaks = false;
global title_str

switch option
case 1
	load(sprintf('/home/anataraj/NIH-craving/misc_mats/P20_079_base_bike.mat'));
	ecg_mat = base';
	peak_labels = zeros(1, length(ecg_mat));
	peak_labels(base_rr) = 1;
	time_matrix = base_time;
	title_str = 'Baseline';
case 2
	load(sprintf('/home/anataraj/NIH-craving/misc_mats/P20_079_base_bike.mat'));
	ecg_mat = bike';
	peak_labels = zeros(1, length(ecg_mat));
	peak_labels(bike_rr) = 1;
	time_matrix = bike_time;
	title_str = 'Physical Exercise';
case 3
	load(sprintf('/home/anataraj/NIH-craving/misc_mats/P20_088_garbage.mat'));
	ecg_mat = base';
	peak_labels = zeros(1, length(ecg_mat));
	time_matrix = base_time;
	title_str = 'Garbage';

otherwise, error('Invalid option!');
end

global start_time
start_time = 1; 
global window_length;
window_length = 500;

S.fh = figure('units','pixels',...
		'position', [70, 10, 1300, 720],...
		'menubar', 'none',...
		'name', 'PQRST Interface',...
		'numbertitle', 'off',...
		'resize', 'off');

plot_data();

S.win_text = uicontrol('Style', 'text',...
		  'String', 'WIN Length',...
		  'units', 'pixels',...
		  'FontWeight', 'bold',...
		  'fontsize', 10,...
		  'Position', [20 600 100 20]);

S.disp_poph = uicontrol('Style', 'popup',...
		  'String', '50|100|250|500|1000',...
		  'Position', [20 550 100 50],...
		  'Callback', @update_window_length);

S.win_text = uicontrol('Style', 'text',...
		  'String', 'Shift WIN by',...
		  'units', 'pixels',...
		  'FontWeight', 'bold',...
		  'fontsize', 10,...
		  'Position', [20 540 100 20]);

S.shift_poph = uicontrol('Style', 'popup',...
		  'String', '0|500|1000|10000|100000',...
		  'Position', [20 490 100 50]);

y_location = 470;

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'NEXT WIN',...
		  'Position', [20 y_location 100 20],...
		  'Callback', {@right_shift_start_time, S});

S.disp_l_pushh = uicontrol('Style', 'pushbutton', 'String', 'PREV WIN',...
		  'Position', [20 y_location-30 100 20],...
		  'Callback', {@left_shift_start_time, S});

S.rnd_pushh = uicontrol('Style', 'pushbutton', 'String', 'RAND SAMPLE',...
		  'Position', [20 y_location-60 100 20],...
		  'Callback', {@generate_rand_sample, S});

S.rnd_pushh = uicontrol('Style', 'pushbutton', 'String', 'SHOW R PEAKS',...
		  'Position', [20 y_location-90 100 20],...
		  'Callback', {@show_r_peaks_func, S});

%{
S.pk_pushh = uicontrol('Style', 'pushbutton', 'String', 'LABEL PEAKS',...
		  'Position', [20 y_location-90 100 20],...
		  'Callback', {@monitor_clicks, S});

S.un_pushh = uicontrol('Style', 'pushbutton', 'String', 'UNDO',...
		  'Position', [20 y_location-120 100 20],...
		  'Callback', {@undo_peaks, S});

S.sv_pushh = uicontrol('Style', 'pushbutton', 'String', 'SAVE LABELS',...
		  'Position', [20 y_location-150 100 20],...
		  'Callback', @save_mats);
%}

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'QUIT',...
		  'Position', [20 y_location-180 100 20],...
		  'Callback', @exit_interface);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = exit_interface(varargin)

quit;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = update_window_length(hObj, event)

global window_length
window_length = get(hObj, 'String');
window_length = str2num(window_length(get(hObj, 'Value'), :));

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = right_shift_start_time(varargin)

global start_time;
global ecg_mat;
global window_length;

S = varargin{3};  % Get the structure.
user_choices = get(S.shift_poph, {'string', 'value'});  % Get the users choice.
shift_by = str2num(user_choices{1}(user_choices{2}, :));
start_time = start_time + window_length + shift_by;
if start_time+window_length > length(ecg_mat)
	start_time = length(ecg_mat) - window_length;
end

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = left_shift_start_time(varargin)

global start_time;
global ecg_mat;
global window_length;

S = varargin{3};  % Get the structure.
user_choices = get(S.shift_poph, {'string', 'value'});  % Get the users choice.
shift_by = str2num(user_choices{1}(user_choices{2}, :));
start_time = start_time - window_length - shift_by;
if start_time < 1
	start_time = 1;
end

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = generate_rand_sample(varargin)

global ecg_mat;
global start_time;

time = clock();
rand('twister', sum(100 * clock));
start_time = randi(length(ecg_mat), 1);

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = show_r_peaks_func(varargin)

global show_r_peaks;
show_r_peaks = true;

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_data()

global ecg_mat;
global peak_labels;
global time_matrix;
global start_time;
global window_length;
global show_r_peaks;
global title_str;

nIndicators = 6;
label_str = {'R'};
label_clr = {'R'};

data_idx = start_time:start_time+window_length;
if min(ecg_mat(data_idx)) == max(ecg_mat(data_idx))
	y_entries = linspace(1, 5, nIndicators);
	y_lim = [1, 5];
else
	y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);
	y_lim = [min(ecg_mat(data_idx)), max(ecg_mat(data_idx))];
end

plot(1:length(data_idx), ecg_mat(1, data_idx), 'b-', 'LineWidth', 2); hold on;
grid on;
xlim([0, length(data_idx)]);
ylabel('Millivolts');
ylim(y_lim);
set(gca, 'XTickLabel', time_matrix(1, [data_idx(1:window_length/10:window_length), data_idx(end)]));
title(title_str);

if show_r_peaks
	win_peak_labels = peak_labels(1, data_idx);
	for lbl = 1:length(label_str)
		clear idx3;
		idx3 = win_peak_labels == lbl;
		text(find(idx3), ecg_mat(1, data_idx(find(idx3))), label_str{lbl}, 'FontSize', 12, 'FontWeight', 'Bold',...
										'color', label_clr{lbl});
	end
end
hold off;

