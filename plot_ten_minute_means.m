function[] = plot_ten_minute_means(subject_id, varargin)

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

%{
if visible_flag
	figure();
else
	figure('visible', 'off');
end
%}

for e = 1:length(this_subj_exp_sessions)
	figure(e);
	set(gcf, 'Position', [10, 10, 1200, 800]);

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
					xlim([0, get_project_settings('nInterpolatedFeatures')+50]); hold on;
					ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
					grid on; 
					if strcmp(subject_id, 'P20_048'), ylim([-1, 0.5]); end
					if strcmp(subject_id, 'P20_058'), ylim([-1, 2]); end
				end
				if visible_flag, pause(1); end
				legend_cntr = legend_cntr + 1;
				legend(legend_str);
			end
		end
	end
end
title(sprintf('%s, Mean ECG in ten minute intervals', get_project_settings('strrep_subj_id', subject_id)));

% file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

