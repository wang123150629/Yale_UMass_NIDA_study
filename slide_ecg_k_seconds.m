function[subject_profile] = slide_ecg_k_seconds(subject_profile)

how_many_sec_per_win = get_project_settings('how_many_sec_per_win');
result_dir = get_project_settings('results');
subject_id =  subject_profile.subject_id;

for v = 1:subject_profile.nEvents
	if ~isfield(subject_profile.events{v}, sprintf('slide%d_win_mat_path', how_many_sec_per_win))
		load(sprintf('%s.mat', subject_profile.events{v}.preprocessed_mat_path));
		exp_sessions = subject_profile.events{v}.exp_sessions;
		sliding_ksec_win = struct();
		sliding_ksec_win.rr_mat = [];
		sliding_ksec_win.pqrst_mat = [];
		for e = 1:length(exp_sessions)
			[rr_mat, pqrst_mat] = slide_win_and_build_dataset(preprocessed_data{1, e}, subject_profile, v);
			sliding_ksec_win.rr_mat = [sliding_ksec_win.rr_mat;...
							[rr_mat, repmat(exp_sessions(e), size(rr_mat, 1), 1)]];
			sliding_ksec_win.pqrst_mat = [sliding_ksec_win.pqrst_mat;...
							[pqrst_mat, repmat(exp_sessions(e), size(rr_mat, 1), 1)]];
		end
		mat_path = fullfile(result_dir, subject_id, sprintf('%s_slide%d_win',...
					subject_profile.events{v}.file_name, how_many_sec_per_win));
		save(mat_path, '-struct', 'sliding_ksec_win');
		subject_profile.events{v} = setfield(subject_profile.events{v},...
					sprintf('slide%d_win_mat_path', how_many_sec_per_win), mat_path);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[rr_mat, pqrst_mat] = slide_win_and_build_dataset(preprocessed_data, subject_profile, event)

plot_dir = get_project_settings('plots');
result_dir = get_project_settings('results');
image_format = get_project_settings('image_format');
cut_off_heart_rate = get_project_settings('cut_off_heart_rate');
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
how_many_sec_per_win = get_project_settings('how_many_sec_per_win');
nFeatures = get_project_settings('nInterpolatedFeatures');

dosage_levels = subject_profile.events{event}.dosage_levels;

rr_mat = [];
pqrst_mat = [];

for d = 1:length(dosage_levels)
	target_dosage_idx = preprocessed_data.dosage_labels == dosage_levels(d); % pick out rows
	if ~isempty(find(target_dosage_idx))
		interpolated_ecg = preprocessed_data.interpolated_ecg(target_dosage_idx, :); % pick out corresponding features
		hold_start_end_indices = preprocessed_data.hold_start_end_indices(target_dosage_idx, :); % start end indices
		rr_intervals = preprocessed_data.valid_rr_intervals(target_dosage_idx, :); % start end indices
		assert(all(hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) >= cut_off_heart_rate(1) &...
			   hold_start_end_indices(:, 2)-hold_start_end_indices(:, 1) <= cut_off_heart_rate(2)));
		x_size = preprocessed_data.x_size(dosage_levels(d) == dosage_levels);
		x_time = preprocessed_data.x_time{dosage_levels(d) == dosage_levels};

		% This is taking the entire, say baseline, session and breaking it into k second windows. It is important to note that
		% each window is of length 7500 (250 x 30 seconds) and the window slides by 250 i.e. one full second
		samples_clusters = [1:raw_ecg_mat_time_res:(x_size-(raw_ecg_mat_time_res * how_many_sec_per_win)+1);...
  				    (raw_ecg_mat_time_res * how_many_sec_per_win):raw_ecg_mat_time_res:x_size]';
		assert(length(unique(samples_clusters(:, 2) - samples_clusters(:, 1))) == 1);

		for s = 1:size(samples_clusters, 1)
			% Finding samples that lie within this k sec window. This could result in say samples 2, 3, 4, 5
			target_idx = intersect(find(hold_start_end_indices(:, 1) >= samples_clusters(s, 1)),...
				  	       find(hold_start_end_indices(:, 2) <= samples_clusters(s, 2)));
			% Picking out those four samples i.e. 2, 3, 4, 5
			interpolated_ecg_within_win = interpolated_ecg(target_idx, :);

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% RR:
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Passing in only those four samples i.e. 2, 3, 4, 5
			[mean_for_this_chunk, mean_rr_intervals, good_samples] =...
						find_samples_that_qualify(interpolated_ecg_within_win, rr_intervals(target_idx));
			rr_mat = [rr_mat; mean_for_this_chunk, mean_rr_intervals,...
				x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
				x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
				length(good_samples), dosage_levels(d)];

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% PQRST:
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% First convert the RR samples into PQRST samples
			pqrst_interpolated_ecg_within_win = [interpolated_ecg_within_win(1:end-1, (nFeatures/2)+1:nFeatures),...
		   					     interpolated_ecg_within_win(2:end, 1:nFeatures/2)];

			% Passing in only those four samples i.e. 2, 3, 4, 5
			[mean_for_this_chunk, mean_rr_intervals, good_samples] =...
						find_samples_that_qualify(pqrst_interpolated_ecg_within_win, rr_intervals(target_idx));
			pqrst_mat = [pqrst_mat; mean_for_this_chunk, mean_rr_intervals,...
				x_time(samples_clusters(s, 1), 1), x_time(samples_clusters(s, 1), 2),...
				x_time(samples_clusters(s, 2), 1), x_time(samples_clusters(s, 2), 2),...
				length(good_samples), dosage_levels(d)];
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[mean_for_this_chunk, mean_rr_intervals, good_samples] = find_samples_that_qualify(interpolated_ecg_within_win, rr_intervals)

nStddev = get_project_settings('how_many_std_dev');
nInterpolatedFeatures = get_project_settings('nInterpolatedFeatures');
mean_for_this_chunk = zeros(1, size(interpolated_ecg_within_win, 2));
mean_rr_intervals = 0;
good_samples = [];

if ~isempty(interpolated_ecg_within_win)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Standardizing the samples for those four samples. Recall the standardizing is done per sample
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Gathering mean
	sample_means = mean(interpolated_ecg_within_win, 2);
	% Gathering the std dev
	sample_std = std(interpolated_ecg_within_win, [], 2);
	% standardizing the instances
	std_interpolated_ecg = bsxfun(@rdivide, bsxfun(@minus, interpolated_ecg_within_win,...
								sample_means), sample_std);
	% We will need to gather the mean again here to idenitfy samples > 3 std dev
	mean_features = mean(std_interpolated_ecg, 1);
	std_features = std(std_interpolated_ecg, [], 1);
	lower = repmat(mean_features - nStddev*std_features, size(std_interpolated_ecg, 1), 1);
	upper = repmat(mean_features + nStddev*std_features, size(std_interpolated_ecg, 1), 1);
	good_samples = find(sum(std_interpolated_ecg >= lower &...
			        std_interpolated_ecg <= upper, 2) == nInterpolatedFeatures);
	
	% Only those samples that qualify. If this results in [2, 3] then mean_for_this_chunk will be
	% mean over samples [3, 4] since 3 qnd 4 are in positions 2 and 3
	if ~isempty(good_samples)
		mean_for_this_chunk = mean(std_interpolated_ecg(good_samples, :), 1);
		mean_rr_intervals = mean(rr_intervals(good_samples, :), 1);
	end
	% fprintf('%0.4f, %0.4f, %d\n', mean_rr_intervals, mean(rr_intervals), size(interpolated_ecg_within_win, 1));
	% if abs(mean_rr_intervals - mean(rr_intervals)) > 10, keyboard; end
end

%{
	if ~isempty(lower_bound) & ~isempty(upper_bound)
	font_size = get_project_settings('font_size');
	le_fs = font_size(1); xl_fs = font_size(2); yl_fs = font_size(3);
	xt_fs = font_size(4); yt_fs = font_size(5); tl_fs = font_size(6);
	figure('visible', 'off')
	set(gcf, 'PaperPosition', [0 0 6 6]);
	set(gcf, 'PaperSize', [6 6]);
	plot(mean_for_this_chunk, 'g-', 'LineWidth', 6); hold on;
	plot(lower_bound(1, :), 'g--', 'LineWidth', 3);
	plot(upper_bound(1, :), 'g--', 'LineWidth', 3);
	x_tick = get(gca, 'XtickLabel'); % ylim([0, 5]);
	set(gca, 'XtickLabel', str2num(x_tick) .* 4, 'FontSize', xt_fs, 'FontWeight', 'b', 'FontName', 'Times');
	xlabel('Interpolated(400 milliseconds)', 'FontSize', xl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	ylabel('std. millivolts', 'FontSize', yl_fs, 'FontWeight', 'b', 'FontName', 'Times');
	file_name = sprintf('/home/anataraj/Desktop/mean_win/mean_win%d', s);
	saveas(gcf, file_name, 'pdf')
	end
%}
