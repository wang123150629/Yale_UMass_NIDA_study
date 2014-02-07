function[] = view_test_peaks(rec_no, analysis_id)

close all;
plot_dir = get_project_settings('plots');
results_dir = get_project_settings('results');

global record_no
record_no = rec_no;
global target_rec
target_rec = 'P20_040';
global prblm_start_time
prblm_start_time = 0;
global start_time
start_time = 1; 
global window_length;
window_length = 1000;
global label_str
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
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

S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'NEXT CLUSTER',...
		  'Position', [20 y_location-180 100 20],...
		  'Callback', @next_cluster);

%{
S.ex_pushh = uicontrol('Style', 'pushbutton', 'String', 'PRBL SEG',...
		  'Position', [20 y_location-210 100 20],...
		  'Callback', @problematic_segments);
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = next_cluster(varargin)

global ground_truth_locations;
global current_cluster;
global start_time;
global window_length;

start_time = ground_truth_locations(find(ground_truth_locations > current_cluster));
start_time = start_time(1);
current_cluster = start_time + window_length;

plot_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = problematic_segments(varargin)

global prblm_start_time;
global puwave_labels;
global crf_labels;
global window_length;
global start_time;

b = find(crf_labels > 0 & crf_labels < 6 & crf_labels ~= puwave_labels);
start_time = b(find(b > prblm_start_time));
start_time = start_time(1);
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
nLabels = numel(label_str);
label_clr = {'R', 'B', 'G', 'M', 'C', 'K'};

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
xlim([0, length(data_idx)]); grid on;
ylabel('Millivolts', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
ylim(y_lim);
% set(gca, 'XTickLabel', time_matrix(1, [data_idx(1:window_length/10:window_length), data_idx(end)]),...
%					'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');

for lbl = 1:length(label_str)
	idxx = find(ground_truth(data_idx) == lbl);
	if ~isempty(idxx)
		text(idxx, raw_ecg_data(1, idxx), sprintf('%s', label_str{lbl}), 'color', sprintf('R'));
	end
end
hold off;

keyboard

%{
label_str2 = {'o', '+', 's', '*', 'd', '+'};

[rr, rs] = rrextract(raw_ecg_data(data_idx)', 250, 0.05);
rr_start_end = [rr(1:end-1); rr(2:end)-1]';
heart_rate = (1000 * 60) ./ (4 .* mean(rr_start_end(:, 2) - rr_start_end(:, 1)));
text(900, max(raw_ecg_data(data_idx)) + 10, sprintf('HR=%0.2f', heart_rate));

grid on;
win_puwave_labels = puwave_labels(1, data_idx);

if strcmp(record_no(1:length(target_rec)), target_rec) | strcmp(record_no(1:length(target_rec)), target_rec)
	win_peak_labels_crf = crf_labels(1, data_idx);
end

for lbl = 1:length(label_str)-1
	clear idx3;
	idx3 = win_puwave_labels == lbl;
	text(find(idx3), raw_ecg_data(1, data_idx(find(idx3))), label_str{lbl}, 'FontSize', 16, 'FontWeight', 'Bold',...
									'color', label_clr{lbl});
	if strcmp(record_no(1:length(target_rec)), target_rec) | strcmp(record_no(1:length(target_rec)), target_rec)
		clear idx4;
		idx4 = win_peak_labels_crf == lbl;

		switch lbl
		case {1, 3, 5}
			%text(find(idx4), raw_ecg_data(1, data_idx(find(idx4))) - 7, label_str2{lbl}, 'FontSize', 20,...
			% 'FontWeight', 'Bold', 'color', label_clr{lbl});
			plot(find(idx4), raw_ecg_data(1, data_idx(find(idx4))) - 7, sprintf('%s%s', label_str2{lbl}, label_clr{lbl}),...
			'MarkerSize', 10, 'MarkerFaceColor', label_clr{lbl});

		case {2, 4}
			%text(find(idx4), raw_ecg_data(1, data_idx(find(idx4))) + 7, label_str2{lbl}, 'FontSize', 20,...
			% 'FontWeight', 'Bold', 'color', label_clr{lbl});
			plot(find(idx4), raw_ecg_data(1, data_idx(find(idx4))) + 7, sprintf('%s%s', label_str2{lbl}, label_clr{lbl}),...
			'MarkerSize', 15);
		end
	end
end	
%}

