function[] = plot_qt_interval()

close all;

number_of_subjects = 3;
[subject_id, subject_session, subject_threshold] = get_subject_ids(number_of_subjects);
dosage_levels = get_project_settings('dosage_levels');

for s = 1:number_of_subjects
	qt_length{s} = fetch_qt_length(subject_id{s}, [0:4], [8, 16, 32, -3], true, true);
end

figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
subj_marker_str = {'-', ':', '--'};
line_colors = {[219,147,122], [0,0,0], [162,205,90]};
dos_marker_str = {'r*', 'b*', 'g*', 'm*'};
h1 = [];
for s = 1:number_of_subjects
	subplot(number_of_subjects, 1, s);
	plot(qt_length{s}(:, 3)-qt_length{s}(:, 1), 'color', line_colors{s}./255, 'LineWidth', 2);
	hold on; ylim([25, 50]);
	for d = 1:length(dosage_levels)
		qt_idx = find(qt_length{s}(:, end) == dosage_levels(d));
		if s == 3
			h=plot(qt_idx, qt_length{s}(qt_idx, 3)-qt_length{s}(qt_idx, 1), dos_marker_str{d});
			h1=[h1, h];
		else
			plot(qt_idx, qt_length{s}(qt_idx, 3)-qt_length{s}(qt_idx, 1), dos_marker_str{d});
		end
	end
end
ylabel('QT length');
xlabel('Exp. sess in ten minute chunks');
set(gca, 'XTickLabel', '');
legend(h1, '8mg', '16mg', '32mg', 'baseline', 'Location', 'SouthEast');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[qt_length] = fetch_qt_length(subject_id, varargin)

exp_sessions = get_project_settings('exp_sessions');
dosage_levels = get_project_settings('dosage_levels');
result_dir = get_project_settings('results');
this_subj_exp_sessions = get_project_settings('exp_sessions');
this_subj_dosage_levels = get_project_settings('dosage_levels');
visible_flag = false;
pqrst_flag = false;

if length(varargin) > 0
	switch length(varargin)
	case 1
		this_subj_exp_sessions = varargin{1};
	case 2
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
	case 3
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
		visible_flag = varargin{3};
	case 4
		this_subj_exp_sessions = varargin{1};
		this_subj_dosage_levels = varargin{2};
		visible_flag = varargin{3};
		pqrst_flag = varargin{4};
	end
end

if ~exist(fullfile(result_dir, subject_id, sprintf('ten_min_chunks.mat')))
	error('File ''ten_min_chunks.mat'' does not exist!');
else
	load(fullfile(result_dir, subject_id, sprintf('ten_min_chunks.mat')));
end

if visible_flag
	figure();
else
	figure('visible', 'off');
end
set(gcf, 'Position', [10, 10, 1200, 800]);

qt_length = [];
for e = 1:length(this_subj_exp_sessions)
	legend_str = {};
	legend_cntr = 1;
	if pqrst_flag
		ten_minute_means =...
			ten_min_chunks{1, exp_sessions == this_subj_exp_sessions(e)}.pqrst_chunk_ten_min_session;
	else
		ten_minute_means =...
			ten_min_chunks{1, exp_sessions == this_subj_exp_sessions(e)}.rr_chunk_ten_min_session;
	end

	colors = jet(size(ten_minute_means, 1));
	for d = 1:length(this_subj_dosage_levels)
	for s = 1:size(ten_minute_means, 1)
	if any(ten_minute_means(s, end) == this_subj_dosage_levels(d))
		plot(ten_minute_means(s, 1:end-6), 'color', colors(s, :));
		legend_str{legend_cntr} = sprintf('%d|%02d:%02d-%02d:%02d,%d samples',...
				ten_minute_means(s, end),...
				ten_minute_means(s, end-5), ten_minute_means(s, end-4),...
				ten_minute_means(s, end-3), ten_minute_means(s, end-2),...
				ten_minute_means(s, end-1));
		if legend_cntr == 1
			hold on; grid on;
			xlim([0, get_project_settings('nInterpolatedFeatures')+50]);
			ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
			if strcmp(subject_id, 'P20_048'), ylim([-1, 0.5]); end
			if strcmp(subject_id, 'P20_058'), ylim([-2, 2]); end
		end
		legend_cntr = legend_cntr + 1;
		legend(legend_str);
		[q_point, t_point] = find_qt_points(ten_minute_means(s, 1:end-6),...
						       ten_minute_means(s, end-1), colors(s, :));
						       
		qt_length = [qt_length; q_point, t_point, ten_minute_means(s, end-1), ten_minute_means(s, end)];
		% if visible_flag, pause(1); end
	end
	end
	end
end
title(sprintf('%s, Mean ECG in ten minute intervals', get_project_settings('strrep_subj_id', subject_id)));

% file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[q_point, t_point] = find_qt_points(ten_minute_means, nSamples, set_colors)

[maxtab, mintab] = peakdet(ten_minute_means, 0.2);
if size(maxtab, 1) >= 1 & size(mintab, 1) >= 1;
	maxtab = maxtab(maxtab(:, 1) > 2, :); % leaving out the first point
	mintab = mintab(mintab(:, 1) > maxtab(1, 1), :); % retainig the troughs only after the first peak
	q_point = mintab(1, :);
	t_point = maxtab(maxtab(:, 1) > 70, :);

	if size(q_point, 1) == 1 & size(t_point, 1) == 1;
		h1=plot(q_point(1, 1), q_point(1, 2), '*', 'color', set_colors);
		hAnnotation = get(h1, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');

		h2=plot(t_point(1, 1), t_point(1, 2), 's', 'color', set_colors);
		hAnnotation = get(h2, 'Annotation');
		hLegendEntry = get(hAnnotation', 'LegendInformation');
		set(hLegendEntry, 'IconDisplayStyle', 'off');
	else
		disp(sprintf('Missing either q or t point'));
		q_point = [0, 0]; t_point = [0, 0];
	end
else
	disp(sprintf('No peaks detected'));
	q_point = [0, 0]; t_point = [0, 0];
end

