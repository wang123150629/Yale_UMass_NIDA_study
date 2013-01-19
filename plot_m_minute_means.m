function[] = plot_m_minute_means(subject_id, how_many_minutes, varargin)

% plot_m_minute_means('P20_040', 10, 0:4, [8, 16, 32, -3], true, true)

close all;

exp_sessions = get_project_settings('exp_sessions');
dosage_levels = get_project_settings('dosage_levels');
result_dir = get_project_settings('results');
% This could be overwritten with varargin
this_subj_exp_sessions = get_project_settings('exp_sessions');
this_subj_dosage_levels = get_project_settings('dosage_levels');
visible_flag = false;
pqrst_flag = false;

nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
rr_col = nInterpolatedFeatures + 1;
start_hh_col = nInterpolatedFeatures + 2;
start_mm_col = nInterpolatedFeatures + 3;
end_hh_col = nInterpolatedFeatures + 4;
end_mm_col = nInterpolatedFeatures + 5;
nSamples_col = nInterpolatedFeatures + 6;
dosage_col = nInterpolatedFeatures + 7;

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

if ~exist(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', how_many_minutes)))
	error(sprintf('File ''chunks_%d_min.mat'' does not exist!', how_many_minutes));
else
	load(fullfile(result_dir, subject_id, sprintf('chunks_%d_min.mat', how_many_minutes)));
end

for e = 1:length(this_subj_exp_sessions)
	if visible_flag
		figure(e);
	else
		figure('visible', 'off');
	end
	set(gcf, 'Position', [10, 10, 1200, 800]);
	title(sprintf('%s, session=%d, %d minute intervals', get_project_settings('strrep_subj_id', subject_id),...
			this_subj_exp_sessions(e), how_many_minutes));
	hold on;
	legend_str = {};
	legend_cntr = 1;

	if pqrst_flag
		individual_chunks =...
			chunks_m_min{1, exp_sessions == this_subj_exp_sessions(e)}.pqrst_chunk_m_min_session;
	else
		individual_chunks =...
			chunks_m_min{1, exp_sessions == this_subj_exp_sessions(e)}.rr_chunk_m_min_session;
	end

	colors = jet(size(individual_chunks, 1));
	for d = 1:length(this_subj_dosage_levels)
		for s = 1:size(individual_chunks, 1)
			if any(individual_chunks(s, dosage_col) == this_subj_dosage_levels(d))
				plot(individual_chunks(s, ecg_col), 'color', colors(s, :));
				legend_str{legend_cntr} = sprintf('%d|%02d:%02d-%02d:%02d,%d samples',...
						individual_chunks(s, dosage_col),...
						individual_chunks(s, start_hh_col),...
						individual_chunks(s, start_mm_col),...
						individual_chunks(s, end_hh_col),...
						individual_chunks(s, end_mm_col),...
						individual_chunks(s, nSamples_col));
				if legend_cntr == 1
					xlim([0, get_project_settings('nInterpolatedFeatures')+50]);
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

% file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
% savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

