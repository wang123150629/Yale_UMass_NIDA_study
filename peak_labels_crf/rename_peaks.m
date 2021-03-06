function[] = rename_peaks(subject_id, approach, varargin)

% rename_peaks('P20_040', 1, false)

save_flag = false;
if length(varargin) == 1
	save_flag = varargin{1};
end

rename_peaks_subject(subject_id, approach, save_flag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = rename_peaks_subject(subject_id, approach, save_flag)

results_dir = get_project_settings('results');
clusters_apart = get_project_settings('clusters_apart');

load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
switch subject_id
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', subject_id);
otherwise
	magic_idx = 1:size(labeled_peaks, 2);
end
labeled_peaks = labeled_peaks(:, magic_idx);
peak_idx = labeled_peaks(3, :) > 0;
labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_peaks_idx = peak_idx & labeled_idx;
valid_peak_idx = find(labeled_peaks_idx);

valid_clusters = [0, find(diff(valid_peak_idx) > clusters_apart)];
ordered_valid_clusters = 1:length(valid_clusters);
valid_clusters = [valid_clusters, length(valid_peak_idx)];
one_sided_left = [5, 1:4];
one_sided_right = [2:5, 1];

updated_labels = labeled_peaks(3, :);
unknown_peak_count = zeros(1, 55);

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
		elseif isempty(left_label) & isempty(right_label)
			error('A U occuring by itself!');
		end
		switch approach
		case 1
			% Inter and intra
			switch new_labels(u_labels(n))
			case 12, new_labels(u_labels(n)) = 6;
			case 13, new_labels(u_labels(n)) = 6;
			case 23, new_labels(u_labels(n)) = 6;
			case 34, new_labels(u_labels(n)) = 6;
			case 35, new_labels(u_labels(n)) = 6;
			case 45, new_labels(u_labels(n)) = 6;
			case 41, new_labels(u_labels(n)) = 7;
			case 51, new_labels(u_labels(n)) = 7;
			case 52, new_labels(u_labels(n)) = 7;
			case 53, new_labels(u_labels(n)) = 7;
			otherwise, error('New U peak!');
			end
		otherwise
			error('Invalid U peak labelling approach!');
		end
		unknown_peak_count(new_labels(u_labels(n))) = unknown_peak_count(new_labels(u_labels(n))) + 1;
	end
	updated_labels(1, temp_idx) = new_labels;
end
assert(sum(updated_labels >= 6 & updated_labels < 100) == sum(unknown_peak_count));
assert(sum(labeled_peaks(3, :) == 6) == sum(unknown_peak_count));

switch approach
case 1
	relabel_str = 'interintra';
	assert(length(unique(updated_labels)) == 9);
end

if save_flag
	load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
	with_magicidx_updated_labels = zeros(1, size(labeled_peaks, 2));
	with_magicidx_updated_labels(1, magic_idx) = updated_labels;
	peaks_information = struct();
	peaks_information.labeled_peaks = [labeled_peaks; with_magicidx_updated_labels];
	peaks_information.time_matrix = [];
	save(fullfile(results_dir, 'labeled_peaks', sprintf('%s_uu_%s_grnd_trth.mat', subject_id, relabel_str)),...
								'-struct', 'peaks_information');
end

