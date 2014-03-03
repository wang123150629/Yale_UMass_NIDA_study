function[] = check_peaks_v2(subject_id)

close all;

global window_length;
window_length = 500;
global start_time
start_time = 1;
global label_str
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
global subj_id
subj_id = subject_id;
global ecg_mat
global ecg_peaks
global indicator_matrix
global time_matrix

load(fullfile(pwd, sprintf('subject_%d_grnd_trth.mat', subj_id)));
ecg_mat = labeled_peaks(1, :)';
ecg_peaks = labeled_peaks(2, :);
indicator_matrix = labeled_peaks(3, :);
% Note time_matrix is automatically initialized when loading the struct

print_peak_stats()

S.fh = figure('units','pixels',...
		'position', [70, 10, 1300, 650],...
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

S.pk_pushh = uicontrol('Style', 'pushbutton', 'String', 'LABEL PEAKS',...
		  'Position', [20 y_location-90 100 20],...
		  'Callback', {@monitor_clicks, S});

S.un_pushh = uicontrol('Style', 'pushbutton', 'String', 'UNDO',...
		  'Position', [20 y_location-120 100 20],...
		  'Callback', {@undo_peaks, S});

S.sv_pushh = uicontrol('Style', 'pushbutton', 'String', 'SAVE LABELS',...
		  'Position', [20 y_location-150 100 20],...
		  'Callback', @save_mats);

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'QUIT',...
		  'Position', [20 y_location-180 100 20],...
		  'Callback', @exit_interface);

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'SNAPSHOT',...
		  'Position', [20 y_location-210 100 20],...
		  'Callback', @take_snapshot);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = take_snapshot(varargin)

timestamp = clock();
file_name = sprintf('%s/lbl_peaks_snap_%d_%d_%d', pwd, timestamp(4), timestamp(5), round(timestamp(6), 0));

saveas(gcf, file_name, 'pdf') % Save figure

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
function[] = save_mats(varargin)

global subj_id;
global ecg_mat;
global ecg_peaks;
global indicator_matrix;
global time_matrix;
assert(isequal(size(indicator_matrix, 2), size(ecg_peaks, 2)));
assert(isequal(size(indicator_matrix, 2), size(ecg_mat, 1)));
labeled_peaks = [ecg_mat'; ecg_peaks; indicator_matrix];

print_peak_stats()

peaks_information = struct();
peaks_information.labeled_peaks = labeled_peaks;
peaks_information.time_matrix = time_matrix;

save(fullfile(pwd, sprintf('subject_%d_grnd_trth.mat', subj_id)), '-struct', 'peaks_information');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = generate_rand_sample(varargin)

global ecg_mat;
global start_time;

time = clock();
rand('twister', sum(100 * clock));
start_time = randi(length(ecg_mat), 1);

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = undo_peaks(varargin)

global start_time;
global window_length;
global indicator_matrix;
global previous_peak_location;
data_idx = start_time:start_time+window_length;

undo_peak_locations = find(indicator_matrix(1, data_idx) > 0 & indicator_matrix(1, data_idx) < 7);
if ~isempty(undo_peak_locations)
	previous_peak_location = data_idx(undo_peak_locations(end));
	indicator_matrix(1, previous_peak_location) = 100;
end

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = monitor_clicks(varargin)

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;

data_idx = start_time:start_time+window_length;
peak_locations = find(indicator_matrix(1, data_idx) == 100);
fprintf('New chunk=%d\n', length(peak_locations));

for p = 1:length(peak_locations)
	if indicator_matrix(1, data_idx(peak_locations(p))) == 100
		fprintf('%d-%d=%d, %d\n', length(peak_locations), p, peak_locations(p), indicator_matrix(1, data_idx(peak_locations(p))));
		plot_data();
		hold on;
		DrawCircle(peak_locations(p), ecg_mat(data_idx(peak_locations(p))), 0.5, 10^4, 'g', 2);
		hold off;

		button_press = true;
		while button_press
			what_is_clicked = waitforbuttonpress;
			if what_is_clicked > 0, button_press = false; end
		end
		character = get(gcf, 'CurrentCharacter');

		switch lower(character)
		case 'p', indicator_matrix(1, data_idx(peak_locations(p))) = 1;
		case 'q', indicator_matrix(1, data_idx(peak_locations(p))) = 2;
		case 'r', indicator_matrix(1, data_idx(peak_locations(p))) = 3;
		case 's', indicator_matrix(1, data_idx(peak_locations(p))) = 4;
		case 't', indicator_matrix(1, data_idx(peak_locations(p))) = 5;
		otherwise, indicator_matrix(1, data_idx(peak_locations(p))) = 6;
		end
	end
	if p == length(peak_locations)
		msgbox('All peaks are labelled in this window!')
	end
end
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_data()

font_size = [12, 20, 20, 12, 12, 20];
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

global start_time;
global window_length;
global ecg_mat;
global ecg_peaks;
global indicator_matrix;
global nIndicators;
global label_str;
nIndicators = numel(label_str);

data_idx = start_time:start_time+window_length;
if min(ecg_mat(data_idx)) == max(ecg_mat(data_idx))
	y_entries = linspace(1, 5, nIndicators);
	y_lim = [1, 5];
else
	y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);
	y_lim = [min(ecg_mat(data_idx)) - 0.01, max(ecg_mat(data_idx)) + 0.01];
end

h = plot(1:length(data_idx), ecg_mat(data_idx, 1), 'LineStyle', '-', 'LineWidth', 3);
set(h, 'LineStyle', '-', 'LineWidth', 3);
set(get(gca, 'Xlabel'), 'String', 'Samples', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'xlim', [0, length(data_idx)]);
set(gca, 'yaxislocation', 'right');
set(get(gca, 'Ylabel'), 'String', 'Millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
set(gca, 'ylim', y_lim);
set(gca, 'YTick', y_entries);
set(gca, 'YTickLabel', get(gca, 'YTickLabel'), 'FontSize', yt_fs, 'FontWeight', 'b', 'FontName', 'Times');

for lbl = 1:nIndicators
	idxx = find(indicator_matrix(data_idx) == lbl);
	if ~isempty(idxx)
		text(idxx, ecg_mat(data_idx(idxx), 1), sprintf('%s', label_str{lbl}), 'color', sprintf('G'),...
									'FontWeight', 'bold', 'FontSize', 16);
	end
	clear idxx;
end

grid on; hold on;
peak_idx = find(ecg_peaks(data_idx) & indicator_matrix(data_idx) > 6);
plot(peak_idx, ecg_peaks(data_idx(peak_idx)), 'r*', 'MarkerSize', 15);
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = print_peak_stats()

global indicator_matrix;
global label_str;

fprintf('--------------\nLabel count\n--------------\n');
for lbl = 1:numel(label_str)
	idxx = find(indicator_matrix == lbl);
	fprintf('%s=%d ', label_str{lbl}, length(idxx));
	% fprintf('%s\n', strcat(sprintf('%s: ', label_str{lbl}), sprintf('%d, ', idxx)));
end
fprintf('\n');

