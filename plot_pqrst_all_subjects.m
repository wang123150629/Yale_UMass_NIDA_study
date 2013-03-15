function[] = plot_pqrst_all_subjects()

number_of_subjects = 7;
slide_or_chunk = 'slide';
event = 1; % cocaine

time_window = get_project_settings('how_many_sec_per_win');
subject_ids = get_subject_ids(number_of_subjects);
result_dir = get_project_settings('results');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
ecg_col = 1:nInterpolatedFeatures;
dosage_col = nInterpolatedFeatures + 7;
exp_session_col = nInterpolatedFeatures + 8;
dosage_levels = {[-3], [8, 16, 32]};
exp_sessions = {[0], [1, 1, 1]};

legend_str = {};
gather_pqrst = {};
for s = 1:number_of_subjects
	gather_pqrst{s} = [];
	subject_profile = load(fullfile(result_dir, subject_ids{s}, sprintf('subject_profile.mat')));
	window_data = load(getfield(subject_profile.events{event}, sprintf('%s%d_win_mat_path', slide_or_chunk, time_window)));
	window_data = window_data.pqrst_mat;
	for n = 1:numel(exp_sessions)
		for l = 1:length(dosage_levels{n})
		target_rows = window_data(:, exp_session_col) == exp_sessions{n}(l) & window_data(:, dosage_col) == dosage_levels{n}(l);
		if ~isempty(target_rows)
			gather_pqrst{s} = [gather_pqrst{s}; mean(window_data(target_rows, ecg_col))];
		end
		end
	end
	legend_str{s} = get_project_settings('strrep_subj_id', subject_ids{s});
end

keyboard

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
colors = jet(number_of_subjects);
set(gca, 'ColorOrder', colors, 'NextPlot', 'replacechildren'); % Change to new colors.
subplot(2, 2, 1); 
plot(ecg_col, gather_pqrst, 'LineWidth', 2);



title(sprintf('Cocaine session'));
hold on; grid on;
xlim([0, get_project_settings('nInterpolatedFeatures')]);
ylabel('std. millivolts'); xlabel('mean(Interpolated ECG)');
legend(legend_str);

keyboard

file_name = sprintf('%s/%s/%s_%s%d_peak%d_detection', get_project_settings('plots'), subject_id,...
		subject_profile.events{event}.file_name, slide_or_chunk, time_window, peak_detect_appr);
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));


