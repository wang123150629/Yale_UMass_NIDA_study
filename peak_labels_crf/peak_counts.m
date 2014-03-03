function[] = peak_counts(subject_id)

% peak_counts('P20_040')

[unknown_peak_count, cluster_sizes, count_u_within_pairs, trans_count] = rename_peaks_subject(subject_id);

label_str = {'P', 'Q', 'R', 'S', 'T'};
labels_exist = unique([count_u_within_pairs(:, 3), count_u_within_pairs(:, 4)]);
nus = 100;
summary_u_count = [];
paired_lbl_str = {};
for i = 1:length(labels_exist)
	for j = 1:length(labels_exist)
		target_rows = count_u_within_pairs(:, 3) == labels_exist(i) & count_u_within_pairs(:, 4) == labels_exist(j);
		u_counts = zeros(1, nus+1);
		if ~isempty(target_rows)
			unique_rows = unique(count_u_within_pairs(target_rows, 1:2), 'rows');
			for u = 1:size(unique_rows, 1)
				matched_entries = sum(sum(count_u_within_pairs(:, 1:2) == repmat(unique_rows(u, :), size(target_rows, 1), 1), 2) == 2);
				assert(matched_entries >= 1 & matched_entries <= nus);
				u_counts(1, matched_entries) = u_counts(1, matched_entries) + 1;
			end
		end
		if any(u_counts > 0)
			u_counts(1, end) = sum(target_rows);
			u_counts = [trans_count(i, j), u_counts];
			summary_u_count = [summary_u_count; u_counts];
			paired_lbl_str{end+1} = sprintf('%s%s', label_str{i}, label_str{j});
		end
	end
end

valid_columns = find(sum(summary_u_count) > 0);
fprintf(', 0, ');
fprintf('%d, ', valid_columns(2:end-1)-1);
fprintf('total U''s\n');
for k = 1:numel(paired_lbl_str)
	fprintf('%s, ', paired_lbl_str{k});
	fprintf('%d, ', summary_u_count(k, valid_columns));
	fprintf('\n');
end

%dispf('U''s b/w %d=%d, total=%d, proportion=%0.4f\n', [find(unknown_peak_count); unknown_peak_count(unknown_peak_count > 0);...
%		trans_count(unknown_peak_count > 0); unknown_peak_count(unknown_peak_count > 0)./trans_count(unknown_peak_count > 0)]);
dispf('Mean cluster size=%0.2f, std dev=%0.4f', mean(cluster_sizes), std(cluster_sizes));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[unknown_peak_count, cluster_sizes, count_u_within_pairs, trans_count] = rename_peaks_subject(subject_id)

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
trans_count = zeros(6, 6);
cluster_sizes = NaN(1, length(ordered_valid_clusters));
count_u_within_pairs = [];

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
			count_u_within_pairs = [count_u_within_pairs; temp_idx(left_label(end)), temp_idx(right_label(1)),...
						old_labels(left_label(end)), old_labels(right_label(1))];
		elseif ~isempty(left_label)
			new_labels(u_labels(n)) = str2num(sprintf('%d%d', old_labels(left_label(end)),...
							one_sided_right(old_labels(left_label(end)))));
			count_u_within_pairs = [count_u_within_pairs; temp_idx(left_label(end)), -1,...
						old_labels(left_label(end)), one_sided_right(old_labels(left_label(end)))];
		elseif ~isempty(right_label)
			new_labels(u_labels(n)) = str2num(sprintf('%d%d', one_sided_left(old_labels(right_label(1))),...
							old_labels(right_label(1))));
			count_u_within_pairs = [count_u_within_pairs; -1, temp_idx(right_label(1)),...
						one_sided_left(old_labels(right_label(1))), old_labels(right_label(1))];
		elseif isempty(left_label) & isempty(right_label)
			error('A U occuring by itself!');
		end
		unknown_peak_count(new_labels(u_labels(n))) = unknown_peak_count(new_labels(u_labels(n))) + 1;
	end

	paired_old_labels = [old_labels(1:end-1); old_labels(2:end)]';
	for p = 1:size(paired_old_labels, 1)
		trans_count(paired_old_labels(p, 1), paired_old_labels(p, 2)) =...
		trans_count(paired_old_labels(p, 1), paired_old_labels(p, 2)) + 1;
	end
end
assert(sum(labeled_peaks(3, :) == 6) == sum(unknown_peak_count));

