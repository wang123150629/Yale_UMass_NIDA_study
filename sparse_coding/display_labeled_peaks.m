function[] = display_labeled_peaks(analysis_id)

close all;
plot_dir = get_project_settings('plots');

global ecg_mat
global peak_labels
global time_matrix
global idx_for_boundary
load(fullfile(plot_dir, 'sparse_coding', analysis_id(1:7), sprintf('%s_labelled_set.mat', analysis_id)));

global start_time
start_time = 1; 
global window_length;
window_length = 500;

S.fh = figure('units','pixels',...
		'position', [70, 10, 1300, 700],...
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
function[] = plot_data()

global ecg_mat;
global peak_labels;
global time_matrix;
global idx_for_boundary;
global start_time;
global window_length;

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

nIndicators = 6;
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
label_clr = {'R', 'G', 'B', 'M', 'C', 'K'};

data_idx = start_time:start_time+window_length;
if min(ecg_mat(data_idx)) == max(ecg_mat(data_idx))
	y_entries = linspace(1, 5, nIndicators);
	y_lim = [1, 5];
else
	y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);
	y_lim = [min(ecg_mat(data_idx)), max(ecg_mat(data_idx))];
end

plot(1:length(data_idx), ecg_mat(1, data_idx), 'b-', 'LineWidth', 2); hold on;
xlim([0, length(data_idx)]);
ylabel('Normalized Millivolts', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim(y_lim);
set(gca, 'XTickLabel', time_matrix(1, [data_idx(1:window_length/10:window_length), data_idx(end)]),...
					'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');

if ~isempty(intersect(idx_for_boundary, data_idx))
	[junk, junk, ii] = intersect(idx_for_boundary, data_idx);
	plot(repmat(ii, nIndicators, 1), repmat(y_entries', 1, length(ii)), 'm--', 'Linewidth', 2);
end

grid on;
win_peak_labels = peak_labels(1, data_idx);
for lbl = 1:length(label_str)
	clear idx3;
	idx3 = win_peak_labels == lbl;
	text(find(idx3), ecg_mat(1, data_idx(find(idx3))), label_str{lbl}, 'FontSize', 12, 'FontWeight', 'Bold',...
									'color', label_clr{lbl});
end
hold off;

