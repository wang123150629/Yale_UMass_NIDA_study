function[] = rename_peaks(subject_id, approach, varargin)

% rename_peaks('P20_040', 1, false)

save_flag = false;
if length(varargin) == 1
	save_flag = varargin{1};
end

[unknown_peak_count, trans_count, cluster_sizes] = rename_peaks_subject(subject_id, approach, save_flag);

dispf('U''s b/w %d=%d, total=%d, proportion=%0.4f\n', [find(unknown_peak_count); unknown_peak_count(unknown_peak_count > 0);...
		trans_count(unknown_peak_count > 0); unknown_peak_count(unknown_peak_count > 0)./trans_count(unknown_peak_count > 0)]);
dispf('Mean cluster size=%0.2f, std dev=%0.4f', mean(cluster_sizes), std(cluster_sizes));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[unknown_peak_count, trans_count, cluster_sizes] = rename_peaks_subject(subject_id, approach, save_flag)

results_dir = get_project_settings('results');
clusters_apart = get_project_settings('clusters_apart');

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
switch subject_id
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', subject_id);
	labeled_peaks = labeled_peaks(:, magic_idx);
end
peak_idx = labeled_peaks(3, :) > 0;
labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_peaks_idx = peak_idx & labeled_idx;
valid_peak_idx = find(labeled_peaks_idx);

valid_clusters = [0, find(diff(valid_peak_idx) > clusters_apart)];
ordered_valid_clusters = 1:length(valid_clusters);
valid_clusters = [valid_clusters, length(valid_peak_idx)];
one_sided_left = [5, 1:4];
one_sided_right = [2:5, 1];

unknown_peak_count = zeros(1, 55);
trans_count = zeros(1, 66);
cluster_sizes = NaN(1, length(ordered_valid_clusters));
updated_labels = labeled_peaks(3, :);

if approach > 2
	updated_labels(updated_labels == 2) = 6;
	updated_labels(updated_labels == 4) = 6;
	updated_labels(updated_labels == 3) = 2;
	updated_labels(updated_labels == 5) = 3;
	updated_labels(updated_labels == 6) = 4;
else
	for cr = 1:length(ordered_valid_clusters)
		temp_idx = [valid_peak_idx(valid_clusters(ordered_valid_clusters(cr))+1:...
				     	   valid_clusters(ordered_valid_clusters(cr)+1))];
		cluster_sizes(1, cr) = length(temp_idx);
		old_labels = labeled_peaks(3, temp_idx);
		assert(all(old_labels > 0 & old_labels < 7));
		valid_labels = find(old_labels > 0 & old_labels < 6);
		new_labels = old_labels;
		u_labels = find(old_labels == 6);
		for n = 1:length(u_labels)
			right_label = valid_labels(valid_labels > u_labels(n));
			left_label = valid_labels(valid_labels < u_labels(n));
			if ~isempty(left_label) & ~isempty(right_label)
				new_labels(u_labels(n)) = str2num(sprintf('%d%d', old_labels(left_label(end)), old_labels(right_label(1))));
			elseif ~isempty(left_label)
				new_labels(u_labels(n)) = str2num(sprintf('%d%d', old_labels(left_label(end)),...
								one_sided_right(old_labels(left_label(end)))));
			elseif ~isempty(right_label)
				new_labels(u_labels(n)) = str2num(sprintf('%d%d', one_sided_left(old_labels(right_label(1))),...
								old_labels(right_label(1))));
			end
			unknown_peak_count(new_labels(u_labels(n))) = unknown_peak_count(new_labels(u_labels(n))) + 1;
			switch approach
			case 1
				switch new_labels(u_labels(n))
				case 12, new_labels(u_labels(n)) = 6;
				case 13, new_labels(u_labels(n)) = 6;
				case 23, new_labels(u_labels(n)) = 6;
				case 34, new_labels(u_labels(n)) = 7;
				case 35, new_labels(u_labels(n)) = 7;
				case 45, new_labels(u_labels(n)) = 7;
				case 51, new_labels(u_labels(n)) = 8;
				case 53, new_labels(u_labels(n)) = 8;
				otherwise, error('New U peak!');
				end
			case 2
				switch new_labels(u_labels(n))
				case 12, new_labels(u_labels(n)) = 6;
				case 13, new_labels(u_labels(n)) = 6;
				case 23, new_labels(u_labels(n)) = 6;
				case 34, new_labels(u_labels(n)) = 6;
				case 35, new_labels(u_labels(n)) = 6;
				case 45, new_labels(u_labels(n)) = 6;
				case 51, new_labels(u_labels(n)) = 7;
				case 53, new_labels(u_labels(n)) = 7;
				otherwise, error('New U peak!');
				end
			otherwise, error('Invalid U peak labelling approach!');
			end		
		end
		updated_labels(1, temp_idx) = new_labels;

		paired_old_labels = [old_labels(1:end-1); old_labels(2:end)]';
		for p = 1:size(paired_old_labels, 1)
			trans_count(str2num(sprintf('%d%d', paired_old_labels(p, 1), paired_old_labels(p, 2)))) =...
			trans_count(str2num(sprintf('%d%d', paired_old_labels(p, 1), paired_old_labels(p, 2)))) + 1;
		end
	end
	assert(sum(updated_labels >= 6 & updated_labels < 100) == sum(unknown_peak_count));
	assert(sum(labeled_peaks(3, :) == 6) == sum(unknown_peak_count));
end

switch approach
case 1
	relabel_str = 'pairs';
	assert(length(unique(updated_labels)) == 10);
case 2
	relabel_str = 'interintra';
	assert(length(unique(updated_labels)) == 9);
case 3
	relabel_str = 'qrsonly';
	assert(length(unique(updated_labels)) == 6);
end

if save_flag
	load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
	with_magicidx_updated_labels = zeros(1, size(labeled_peaks, 2));
	with_magicidx_updated_labels(1, magic_idx) = updated_labels;
	peaks_information = struct();
	peaks_information.labeled_peaks = [labeled_peaks; with_magicidx_updated_labels];
	peaks_information.time_matrix = [];
	save(fullfile(results_dir, 'labeled_peaks', sprintf('%s_relblu_%s_grnd_trth.mat', subject_id, relabel_str)),...
								'-struct', 'peaks_information');
end

