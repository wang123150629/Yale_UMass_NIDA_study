function[] = rename_peaks()

subject_id = 'P20_040';

rename_peaks_subject(subject_id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = rename_peaks_subject(subject_id)

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

updated_labels = zeros(1, size(labeled_peaks, 2));
for cr = 1:length(ordered_valid_clusters)
	temp_idx = [valid_peak_idx(valid_clusters(ordered_valid_clusters(cr))+1:...
			     	   valid_clusters(ordered_valid_clusters(cr)+1))];
	old_labels = labeled_peaks(3, temp_idx);
	assert(all(old_labels > 0 & old_labels < 7));
	u_labels = find(old_labels == 6);
	updated_u = old_labels;
	for n = 1:length(u_labels)
		if u_labels(n) == 1
			updated_u(n) = 200;
		elseif u_labels(n) == length(u_labels)
			updated_u(n) = 300;
		else
			right_label = find(old_labels(n+1:end) > 0 & old_labels(n+1:end) < 6);
			left_label = find(old_labels(1:n-1) > 0 & old_labels(1:n-1) < 6);
			if ~isempty(left_label) & ~isempty(right_label)
				updated_u(n) = str2num(sprintf('%d%d', old_labels(right_label(1)), old_labels(left_label(1))));
			elseif ~isempty(left_label)
				updated_u(n) = 400;
			elseif ~isempty(right_label)
				updated_u(n) = 500;
			end
		end
	end
	keyboard
end
cr_idx = sort(temp_idx);
assert(isequal(sum(diff(cr_idx) > clusters_apart)+1, length(ordered_valid_clusters)));

