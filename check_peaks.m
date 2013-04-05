function[] = check_peaks(varargin)

close all;

subject_id = 'P20_040';
event = 1;

switch event
case 'cocn', event = 1;
case 'exer', event = 2;
case 'mph2', event = 3;
case 'hab', event = 4;
case 'nta', event = 5;
end

subject_profile = subject_profiles(subject_id);

data_dir = get_project_settings('data');
subject_id =  subject_profile.subject_id;
subject_sensor = subject_profile.events{event}.sensor;
subject_timestamp = subject_profile.events{event}.timestamp;
event_label = subject_profile.events{event}.label;

global ecg_mat
% ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG.csv', subject_timestamp)), 1, 0);
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_sensor, subject_timestamp, sprintf('%s_ECG_temp.csv', subject_timestamp)));
ecg_mat = ecg_mat(:, end) .* 0.001220703125;

global ecg_peaks
ecg_peaks = zeros(1, length(ecg_mat));
peak_thres = 0.01;
[maxtab, mintab] = peakdet(ecg_mat, peak_thres);
assert(isempty(intersect(maxtab(:, 1), mintab(:, 1))));
ecg_peaks(maxtab(:, 1)) = maxtab(:, 2);
ecg_peaks(mintab(:, 1)) = mintab(:, 2);

global window_length;
window_length = 50;

global nIndicators
nIndicators = 8;
global indicator_matrix
indicator_matrix = zeros(1, length(ecg_mat));
indicator_matrix(1, maxtab(:, 1)) = 100;
indicator_matrix(1, mintab(:, 1)) = 100;

global start_time
if length(varargin) == 1, start_time = varargin{1};
else, start_time = 1; end

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
		  'String', '50|100|250|500',...
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

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'NEXT WIN',...
		  'Position', [20 470 100 20],...
		  'Callback', {@right_shift_start_time, S});

S.disp_l_pushh = uicontrol('Style', 'pushbutton', 'String', 'PREV WIN',...
		  'Position', [20 440 100 20],...
		  'Callback', {@left_shift_start_time, S});

S.pk_pushh = uicontrol('Style', 'pushbutton', 'String', 'LABEL PEAKS',...
		  'Position', [20 410 100 20],...
		  'Callback', {@monitor_clicks, S});

S.sv_pushh = uicontrol('Style', 'pushbutton', 'String', 'SAVE LABELS',...
		  'Position', [20 370 100 20],...
		  'Callback', @save_mats);

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
function[] = plot_data()

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;
global ecg_peaks;
global nIndicators;
global y_entries

data_idx = start_time:start_time+window_length;
y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);

[ax, h1, h2] = plotyy(1:length(ecg_mat), ecg_mat, 1:length(ecg_mat), indicator_matrix); hold on;
set(h1, 'LineStyle', '-', 'LineWidth', 2);
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 8);

set(get(ax(1), 'Ylabel'), 'String', 'Millivolts');
set(ax(1), 'xlim', [data_idx(1), data_idx(end)]);
set(ax(1), 'YTick', y_entries);
set(ax(1), 'ylim', [min(ecg_mat(data_idx)), max(ecg_mat(data_idx))]);

set(get(ax(2), 'Ylabel'), 'String', 'Peaks');
set(ax(2), 'xlim', [data_idx(1), data_idx(end)]);
set(ax(2), 'ylim', [1, nIndicators]);
set(ax(2), 'YTick', 1:nIndicators);
set(ax(2), 'YTickLabel', {'A-Start', 'P', 'Q', 'R', 'S', 'T', 'U', 'B-Stop'});

grid on;
hold on;
peak_idx = intersect(data_idx, find(ecg_peaks));
plot(peak_idx, ecg_peaks(peak_idx), 'r*', 'MarkerSize', 15);
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = save_mats(varargin)

results_dir = get_project_settings('results');

global ecg_mat;
global ecg_peaks;
global indicator_matrix;
assert(isequal(size(indicator_matrix, 2), size(ecg_peaks, 2)));
assert(isequal(size(indicator_matrix, 2), size(ecg_mat, 1)));
labeled_peaks = [ecg_mat'; ecg_peaks; indicator_matrix];

prompt = {'Enter file name ...'};
dlg_title = 'Save as';
num_lines = 1;
file_name = inputdlg(prompt, dlg_title, num_lines);

save(fullfile(results_dir, 'labeled_peaks', sprintf('%s.mat', file_name{1})), 'labeled_peaks');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = monitor_clicks(varargin)

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;

data_idx = start_time:start_time+window_length;
peak_locations = data_idx(find(indicator_matrix(1, data_idx) == 100));

for p = 1:length(peak_locations)
	plot_data();
	hold on;
	DrawCircle(peak_locations(p), ecg_mat(peak_locations(p)), 0.5, 10^4, 'g', 2);
	hold off;

	button_press = true;
	while button_press
		what_is_clicked = waitforbuttonpress;
		if what_is_clicked > 0, button_press = false; end
	end
	character = get(gcf, 'CurrentCharacter');

	switch lower(character)
	case 'a', indicator_matrix(1, peak_locations(p)) = 1;
	case 'p', indicator_matrix(1, peak_locations(p)) = 2;
	case 'q', indicator_matrix(1, peak_locations(p)) = 3;
	case 'r', indicator_matrix(1, peak_locations(p)) = 4;
	case 's', indicator_matrix(1, peak_locations(p)) = 5;
	case 't', indicator_matrix(1, peak_locations(p)) = 6;
	case 'u', indicator_matrix(1, peak_locations(p)) = 7;
	case 'b', indicator_matrix(1, peak_locations(p)) = 8;
	end
end
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = monitor_clicks1(varargin)

global indicator_matrix;

labeling_peaks = true;
while labeling_peaks
	clicked_on_peak = true;
	while clicked_on_peak
		[peak_location, junk, button] = myginput(1);
		peak_location = round_to(peak_location, 0);
		if button == 3, labeling_peaks = false; return; end
		if indicator_matrix(1, peak_location)
			clicked_on_peak = false;
		end
	end

	if labeling_peaks
		button_press = true;
		peak_label = '';
		while button_press
			switch waitforbuttonpress
			case 0
				[junk, junk, button] = myginput(1);
				if button == 3, labeling_peaks = false; return; end
			case 1
				character = get(gcf, 'CurrentCharacter');
				switch lower(character)
				case 'a', button_press = false; indicator_matrix(1, peak_location) = 1;
				case 'p', button_press = false; indicator_matrix(1, peak_location) = 2;
				case 'q', button_press = false; indicator_matrix(1, peak_location) = 3;
				case 'r', button_press = false; indicator_matrix(1, peak_location) = 4;
				case 's', button_press = false; indicator_matrix(1, peak_location) = 5;
				case 't', button_press = false; indicator_matrix(1, peak_location) = 6;
				case 'b', button_press = false; indicator_matrix(1, peak_location) = 7;
				end
				plot_data();
			end
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_data_old()

global ecg_mat;
global indicator_matrix;
global start_time;
global window_length;
global ecg_peaks;
global nIndicators;
global y_entries

data_idx = start_time:start_time+window_length;
y_entries = linspace(min(ecg_mat(data_idx)), max(ecg_mat(data_idx)), nIndicators);

[ax, h1, h2] = plotyy(1:length(ecg_mat), ecg_mat, 1:length(ecg_mat), indicator_matrix); hold on;
set(h1, 'LineStyle', '-', 'LineWidth', 2);
set(h2, 'LineStyle', 'o', 'MarkerFaceColor', 'g', 'MarkerSize', 15);

set(get(ax(1), 'Ylabel'), 'String', 'Millivolts');
set(ax(1), 'xlim', [data_idx(1), data_idx(end)]);
set(ax(1), 'YTick', y_entries);
set(ax(1), 'ylim', [min(ecg_mat(data_idx)), max(ecg_mat(data_idx))]);

set(get(ax(2), 'Ylabel'), 'String', 'Peaks');
set(ax(2), 'xlim', [data_idx(1), data_idx(end)]);
set(ax(2), 'ylim', [1, nIndicators]);
set(ax(2), 'YTick', 1:nIndicators);
set(ax(2), 'YTickLabel', {'Start', 'P', 'Q', 'R', 'S', 'T', 'Stop'});

grid on;
hold on;
peak_idx = intersect(data_idx, find(ecg_peaks));
plot(peak_idx, ecg_peaks(peak_idx), 'r*', 'MarkerSize', 15);
hold off;

%{
subplot(2, 1, 2);
imagesc(indicator_matrix);
xlim([data_idx(1), data_idx(end)]);
set(gca, 'YTick', 1:nIndicators);
set(gca, 'YTickLabel', {'P', 'Q', 'R', 'S', 'T', 'SS'});
grid on;
% axis off;

data_idx = start_time:start_time+window_length;
peak_locations = find(indicator_matrix(1, data_idx));

for p = 1:length(peak_locations)
	% plot_data();
	% hold on;
	% DrawCircle(peak_locations(p), ecg_mat(peak_locations(p)), 0.5, 10^4, 'g', 2);
	% hold off;
	button_press = true;
	what_is_clicked = -1;
	what_is_clicked = waitforbuttonpress;
	while button_press
		% what_is_clicked = waitforbuttonpress;
		% if what_is_clicked >= 0, button_press = false; end
		what_is_clicked
	end

	keyboard

	switch what_is_clicked
	case 0
		[junk, junk, button] = myginput(1);
		if button == 3, return; end
	case 1
		character = get(gcf, 'CurrentCharacter');

		switch lower(character)
		case 'a', button_press = false; indicator_matrix(1, peak_locations(p)) = 1;
		case 'p', button_press = false; indicator_matrix(1, peak_locations(p)) = 2;
		case 'q', button_press = false; indicator_matrix(1, peak_locations(p)) = 3;
		case 'r', button_press = false; indicator_matrix(1, peak_locations(p)) = 4;
		case 's', button_press = false; indicator_matrix(1, peak_locations(p)) = 5;
		case 't', button_press = false; indicator_matrix(1, peak_locations(p)) = 6;
		case 'b', button_press = false; indicator_matrix(1, peak_locations(p)) = 7;
		end
	end
end

%}


