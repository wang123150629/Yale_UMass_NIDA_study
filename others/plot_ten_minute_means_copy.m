function[] = plot_ten_minute_means(subject_id, dosage, exp_sessions, varargin)

if length(varargin) > 0
	switch length(varargin)
	case 1
		visible_flag = varargin{1};
		pqrst_flag = false;
	case 2
		visible_flag = varargin{1};
		pqrst_flag = varargin{2};
	end
else
	visible_flag = false;
	pqrst_flag = false;
end

result_dir = get_project_settings('results');
if ~exist(fullfile(result_dir, subject_id, sprintf('ten_min_chunks.mat')))
	error('File ''ten_min_chunks.mat'' does not exist!');
else
	load(fullfile(result_dir, subject_id, sprintf('ten_min_chunks.mat')));
end

for e = 1:length(exp_sessions)
	title_str = sprintf('%s, sess=%d, Mean ECG in ten minute intervals',...
					get_project_settings('strrep_subj_id', subject_id), exp_sessions(e));
	if pqrst_flag
		ten_minute_means = ten_min_chunks{1, e}.pqrst_chunk_ten_min_session;
	else
		ten_minute_means = ten_min_chunks{1, e}.rr_chunk_ten_min_session;
	end

	if visible_flag
		figure();
	else
		figure('visible', 'off');
	end
	set(gcf, 'Position', [10, 10, 1200, 800]);
	colors = jet(size(ten_minute_means, 1));

	legend_str = {};
	legend_cntr = 1;
	for d = 1:length(dosage)
		for s = 1:size(ten_minute_means, 1)
			if any(ten_minute_means(s, end) == dosage(d))
				plot(ten_minute_means(s, 1:end-6), 'color', colors(s, :));
				legend_str{legend_cntr} = sprintf('%d|%d:%d-%d:%d,%d samples',...
						ten_minute_means(s, end),...
						ten_minute_means(s, end-5), ten_minute_means(s, end-4),...
						ten_minute_means(s, end-3), ten_minute_means(s, end-2),...
						ten_minute_means(s, end-1));
				if legend_cntr == 1
					xlim([0, 210]); hold on;
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
	title(title_str);
end

keyboard

file_name = sprintf('%s/subj_%s_ten_minute', get_project_settings('plots'), subject_id);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

%if any(dosage > 4)
%	dosage = str2num(strrep(num2str(dosage), num2str(5), '2 3 4'));
%end
%assert(isnumeric(dosage));
% target_idx = find(sum(repmat(ten_minute_means(:, end), 1, size(dosage, 2)) == repmat(dosage,...
%				size(ten_minute_means, 1), 1), 2));
% min_val = min(min(ten_minute_means(target_idx, 1:end-6)));
% max_val = max(max(ten_minute_means(target_idx, 1:end-6)));
% min_val, max_val, title_str
