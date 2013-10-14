function[] = check_peaks(varargin)

% For P20_040_1_3pm_chunk was originally grabbed from timestamps [13.0000   14.0000   56.4360] to [15.0000   54.0000   16.4360]
% check_peaks('P20_040_cocaine_time');
% old; check_peaks('P20_040_1_3pm_chunk');
% old: check_peaks('P20_048_new_labels');

close all;

subject_id = 'P20_040';
peak_thres = 0.02;
event = 1;

subject_profile = subject_profiles(subject_id);

data_dir = get_project_settings('data');
results_dir = get_project_settings('results');
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_label = subject_profile.events{event}.label;

global ecg_mat

% [rr_locations, rr_intervals, heart_rate, trend] = compute_heart_rate(subject_id, ecg_mat, peak_thres);
% start_end_points = round_to(rr_locations(1:end-1) + (diff(rr_locations) / 2), 0);

global ecg_peaks
global window_length;
window_length = 500;
global nIndicators
nIndicators = 6;
global indicator_matrix
global start_time
start_time = 1; 
global time_matrix

if length(varargin) == 1
	load(fullfile(results_dir, 'labeled_peaks', sprintf('%s.mat', varargin{1})));
	ecg_mat = labeled_peaks(1, :)';
	ecg_peaks = labeled_peaks(2, :);
	indicator_matrix = labeled_peaks(3, :);
	% Note time_matrix is automatically initialized when loading the struct
else
	ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp,...
		sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
	ecg_mat = ecg_mat(:, end) .* 0.001220703125;

	ecg_peaks = zeros(1, length(ecg_mat));
	[maxtab, mintab] = peakdet(ecg_mat, peak_thres);
	assert(isempty(intersect(maxtab(:, 1), mintab(:, 1))));
	ecg_peaks(1, maxtab(:, 1)) = maxtab(:, 2);
	ecg_peaks(1, mintab(:, 1)) = mintab(:, 2);

	indicator_matrix = zeros(1, length(ecg_mat));
	indicator_matrix(1, maxtab(:, 1)) = 100;
	indicator_matrix(1, mintab(:, 1)) = 100;

	time_matrix = ecg_mat(:, 4:6)';
	time_matrix = sprintf('%d:%d:%d*', time_matrix);
	time_matrix = regexp(time_matrix, '*', 'split');
end

S.fh = figure('units','pixels',...
		'position', get_project_settings('figure_size'),...
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
function[] = save_mats(varargin)

results_dir = get_project_settings('results');

global ecg_mat;
global ecg_peaks;
global indicator_matrix;
global time_matrix;
assert(isequal(size(indicator_matrix, 2), size(ecg_peaks, 2)));
assert(isequal(size(indicator_matrix, 2), size(ecg_mat, 1)));
labeled_peaks = [ecg_mat'; ecg_peaks; indicator_matrix];

prompt = {'Enter file name(without .mat) ...'};
dlg_title = 'Save as';
num_lines = 1;
file_name = inputdlg(prompt, dlg_title, num_lines);

peaks_information = struct();
peaks_information.labeled_peaks = labeled_peaks;
peaks_information.time_matrix = time_matrix;

save(fullfile(results_dir, 'labeled_peaks', sprintf('%s.mat', file_name{1})), '-struct', 'peaks_information');

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

global previous_peak_location;
global indicator_matrix;
global start_time;
global window_length;

if previous_peak_location > 0
	indicator_matrix(1, previous_peak_location) = 100;
end
data_idx = start_time:start_time+window_length;
peak_locations = find(indicator_matrix(1, data_idx) > 0 & indicator_matrix(1, data_idx) < 7);
if ~isempty(peak_locations)
	previous_peak_location = data_idx(peak_locations(end));
end

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = monitor_clicks(varargin)

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;
global previous_peak_location

data_idx = start_time:start_time+window_length;
peak_locations = find(indicator_matrix(1, data_idx) == 100);
previous_peak_location = -100;

for p = 1:length(peak_locations)
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
	previous_peak_location = data_idx(peak_locations(p));
end
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_data()

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;
global ecg_peaks;
global nIndicators;
global y_entries
global time_matrix;

data_idx = start_time:start_time+window_length;
if min(ecg_mat(data_idx)) == max(ecg_mat(data_idx))
	y_entries = linspace(1, 5, nIndicators);
	y_lim = [1, 5];
else
	y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);
	y_lim = [min(ecg_mat(data_idx)), max(ecg_mat(data_idx))];
end

[ax, h1, h2] = plotyy(1:length(data_idx), ecg_mat(data_idx, 1), 1:length(data_idx), indicator_matrix(1, data_idx)); hold on;
set(h1, 'LineStyle', '-', 'LineWidth', 2);
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 8);

set(get(ax(1), 'Ylabel'), 'String', 'Millivolts');
set(ax(1), 'xlim', [0, length(data_idx)]);
set(ax(1), 'YTick', y_entries);
set(ax(1), 'ylim', y_lim);
set(ax(1), 'XTickLabel', '');

set(get(ax(2), 'Ylabel'), 'String', 'Peaks');
set(ax(2), 'xlim', [0, length(data_idx)]);
set(ax(2), 'ylim', [1, nIndicators]);
set(ax(2), 'YTick', 1:nIndicators);
set(ax(2), 'YTickLabel', {'P', 'Q', 'R', 'S', 'T', 'U'});
set(ax(2), 'XTickLabel', time_matrix(1, [data_idx(1:window_length/10:window_length), data_idx(end)]));

grid on;
hold on;
peak_idx = find(ecg_peaks(data_idx));
plot(peak_idx, ecg_peaks(data_idx(peak_idx)), 'r*', 'MarkerSize', 15);
hold off;

