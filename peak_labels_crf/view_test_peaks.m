function[] = view_test_peaks(rec_no, analysis_id)

% view_test_peaks('P20_040', '1402161a')

close all;
plot_dir = get_project_settings('plots');
results_dir = get_project_settings('results');

global record_no
record_no = rec_no;
global prblm_start_time
prblm_start_time = 0;
global start_time
start_time = 1;
global window_length;
window_length = 500;
global label_str
% label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
label_str = {'P', 'Q', 'R', 'S', 'T', 'Uw', 'Ua'};
clusters_apart = get_project_settings('clusters_apart');

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', record_no)));
clear time_matrix;
switch record_no
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', record_no);
	labeled_peaks = labeled_peaks(:, magic_idx);
end
crf_model = load(sprintf('%s/sparse_coding/%s/%s_results.mat', plot_dir, analysis_id, analysis_id));

global raw_ecg_data
global peak_locations
global ground_truth
global mul_nom_labels
global puwave_labels
global crf_labels
global ground_truth_locations
global current_cluster
global plot_red_crf
global plot_blue_puwave
global plot_green_mul
global plot_black_grnd

raw_ecg_data = labeled_peaks(1, :);
peak_locations = find(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100);
ground_truth = crf_model.ground_truth;
mul_nom_labels = crf_model.mul_nom;
puwave_labels = crf_model.puwave;
crf_labels = crf_model.crf;

ground_truth_locations = find(ground_truth);
ground_truth_clusters = find(diff(ground_truth_locations) > clusters_apart);
ground_truth_clusters = ground_truth_locations([1, ground_truth_clusters+1]);
current_cluster = 0;

plot_red_crf = true;
plot_blue_puwave = true;
plot_green_mul = true;
plot_black_grnd = true;

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
		  'String', '0|50|100|500|1000|10000|100000',...
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

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'NEXT CLUSTER',...
		  'Position', [20 y_location-180 100 20],...
		  'Callback', @next_cluster);

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'BLACK - GRND',...
		  'Position', [20 y_location-210 100 20],...
		  'Callback', {@black_grnd, S});

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'GREEN - MUL',...
		  'Position', [20 y_location-240 100 20],...
		  'Callback', {@green_mul, S});

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'BLUE - PUWAVE',...
		  'Position', [20 y_location-270 100 20],...
		  'Callback', {@blue_puwave, S});

S.disp_r_pushh = uicontrol('Style', 'pushbutton', 'String', 'RED - CRF',...
		  'Position', [20 y_location-300 100 20],...
		  'Callback', {@red_crf, S});

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'PRBL SEG',...
		  'Position', [20 y_location-330 100 20],...
		  'Callback', @problematic_segments);

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'SNAPSHOT',...
		  'Position', [20 y_location-360 100 20],...
		  'Callback', @snapshot);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = snapshot(varargin)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

global raw_ecg_data;
global ground_truth;
global mul_nom_labels;
global puwave_labels;
global crf_labels;
global start_time;
global window_length;
global label_str;
global plot_red_crf;
global plot_blue_puwave;
global plot_green_mul;
global plot_black_grnd;
nLabels = numel(label_str);

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

data_idx = start_time:start_time+window_length;
if min(raw_ecg_data(data_idx)) == max(raw_ecg_data(data_idx))
	min_ecg = min(raw_ecg_data);
	max_ecg = max(raw_ecg_data);
	y_entries = linspace(min_ecg, max_ecg, nLabels);
	y_lim = [min_ecg, max_ecg];
else
	y_entries = linspace(min(raw_ecg_data(data_idx)), max(raw_ecg_data(data_idx)), nLabels);
	y_lim = [min(raw_ecg_data(data_idx)), max(raw_ecg_data(data_idx))];
end

figure('visible', 'off');
set(gcf, 'PaperPosition', [0 0 8 3]);
set(gcf, 'PaperSize', [8 3]);

plot(1:length(data_idx), raw_ecg_data(1, data_idx), 'b-', 'LineWidth', 2); hold on;
xlim([1, length(data_idx)]); grid on;
ylabel('Millivolts', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
xlabel('Time', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim(y_lim);

for lbl = 1:length(label_str)
	offset = 0.01;
	where_to_plot = 0;
	if lbl == 3 | lbl == 5
		offset = -1 * offset;
	end
	
	idxx = find(ground_truth(data_idx) == lbl);
	if ~isempty(idxx) & plot_black_grnd
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}), 'color', sprintf('K'),...
			'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(mul_nom_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_green_mul
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('G'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(puwave_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_blue_puwave
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('B'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(crf_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_red_crf
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('R'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;
end
hold off;

file_name = sprintf('/home/anataraj/NIH-craving/plots/snapshots/%s', datestr(now,'yymmddHHMMSS'));
% savesamesize(gcf, 'file', file_name, 'format', image_format);
saveas(gcf, file_name, 'pdf');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = black_grnd(varargin)

global plot_black_grnd;
plot_black_grnd = ~plot_black_grnd;
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = red_crf(varargin)

global plot_red_crf;
plot_red_crf = ~plot_red_crf;
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = blue_puwave(varargin)

global plot_blue_puwave;
plot_blue_puwave = ~plot_blue_puwave;
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = green_mul(varargin)

global plot_green_mul;
plot_green_mul = ~plot_green_mul;
plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = next_cluster(varargin)

global ground_truth_locations;
global current_cluster;
global start_time;
global window_length;

start_time = ground_truth_locations(find(ground_truth_locations > current_cluster));
start_time = start_time(1) - 10;
current_cluster = start_time + window_length;

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = problematic_segments(varargin)

global prblm_start_time;
global ground_truth;
global crf_labels;
global window_length;
global start_time;

b = find(ground_truth > 0 & ground_truth ~= crf_labels);
start_time = b(find(b > prblm_start_time));
start_time = start_time(1) - 49;
prblm_start_time = start_time + window_length;

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = update_window_length(hObj, event)

global window_length
window_length = get(hObj, 'String');
window_length = str2num(window_length(get(hObj, 'Value'), :));

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = right_shift_start_time(varargin)

global start_time;
global raw_ecg_data;
global window_length;

S = varargin{3};  % Get the structure.
user_choices = get(S.shift_poph, {'string', 'value'});  % Get the users choice.
shift_by = str2num(user_choices{1}(user_choices{2}, :));
start_time = start_time + window_length + shift_by;
if start_time+window_length > length(raw_ecg_data)
	start_time = length(raw_ecg_data) - window_length;
end

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = left_shift_start_time(varargin)

global start_time;
global raw_ecg_data;
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

global raw_ecg_data;
global start_time;

time = clock();
rand('twister', sum(100 * clock));
start_time = randi(length(raw_ecg_data), 1);

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = plot_data()

global raw_ecg_data;
global ground_truth;
global mul_nom_labels;
global puwave_labels;
global crf_labels;
global start_time;
global window_length;
global label_str;
global plot_red_crf;
global plot_blue_puwave;
global plot_green_mul;
global plot_black_grnd;
nLabels = numel(label_str);

font_size = get_project_settings('font_size');
le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);

data_idx = start_time:start_time+window_length;
if min(raw_ecg_data(data_idx)) == max(raw_ecg_data(data_idx))
	min_ecg = min(raw_ecg_data);
	max_ecg = max(raw_ecg_data);
	y_entries = linspace(min_ecg, max_ecg, nLabels);
	y_lim = [min_ecg, max_ecg];
else
	y_entries = linspace(min(raw_ecg_data(data_idx)), max(raw_ecg_data(data_idx)), nLabels);
	y_lim = [min(raw_ecg_data(data_idx)), max(raw_ecg_data(data_idx))];
end

plot(1:length(data_idx), raw_ecg_data(1, data_idx), 'b-', 'LineWidth', 2); hold on;
xlim([1, length(data_idx)]); grid on;
ylabel('Millivolts', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim(y_lim);
% set(gca, 'XTickLabel', time_matrix(1, [data_idx(1:window_length/10:window_length), data_idx(end)]),...
%					'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');

for lbl = 1:length(label_str)
	offset = 0.01;
	where_to_plot = 0;
	if lbl == 3 | lbl == 5
		offset = -1 * offset;
	end
	
	idxx = find(ground_truth(data_idx) == lbl);
	if ~isempty(idxx) & plot_black_grnd
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}), 'color', sprintf('K'),...
			'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(mul_nom_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_green_mul
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('G'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(puwave_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_blue_puwave
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('B'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;

	idxx = find(crf_labels(data_idx) == lbl);
	if ~isempty(idxx) & plot_red_crf
		text(idxx, raw_ecg_data(1, data_idx(idxx))+where_to_plot, sprintf('%s', label_str{lbl}),...
			'color', sprintf('R'), 'FontWeight', 'bold', 'FontSize', 16);
		where_to_plot = where_to_plot + offset;
	end
	clear idxx;
end
hold off;

