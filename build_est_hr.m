function[] = build_est_hr()

results_dir = get_project_settings('results');
idx = 10000:10000:110000;

gather_assigned_hr = NaN(1, 103487);
for i = idx
	load(sprintf('%s/labeled_peaks/assigned_hr_%d.mat', results_dir, i));
	gather_assigned_hr(1, assigned_hr > 0) = assigned_hr(assigned_hr > 0);
end
clear assigned_hr;
assigned_hr = gather_assigned_hr;
isnan(~any(assigned_hr));
save(fullfile(results_dir, 'labeled_peaks/assigned_hr_bl_subtract_sgram_062113.mat'), 'assigned_hr');

keyboard

