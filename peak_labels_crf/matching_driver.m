function[matching_confusion_mat] = matching_driver(vector_a, vector_b, matching_pm, nLabels, disp_flag)

matching_confusion_mat = zeros(nLabels, nLabels);
nWins = 1;
clusters_apart = get_project_settings('clusters_apart');

assert(all(unique(vector_a) >= 0) & all(unique(vector_a) <= 6));
assert(all(unique(vector_b) >= 0) & all(unique(vector_b) <= 5));
vector_a_idx = find(vector_a);
vector_b_idx = find(vector_b);

cluster_boundaries = [0, find(diff(vector_a_idx) > clusters_apart), length(vector_a_idx)];

for c = 2:length(cluster_boundaries)
	vector_a_locations = vector_a_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c));
	vector_a_labels = vector_a(vector_a_locations);
	assert(all(vector_a_labels > 0));

	vector_b_locations = vector_b_idx(vector_b_idx >= min(vector_a_locations) - (nWins * matching_pm) &...
	       		                  vector_b_idx <= max(vector_a_locations) + (nWins * matching_pm));
	vector_b_labels = vector_b(vector_b_locations);
	assert(all(vector_b_labels > 0));

	matching_confusion_mat = matching_confusion_mat +...
			        matching(vector_a_locations, vector_b_locations,...
				vector_a_labels, vector_b_labels, matching_pm, nLabels, disp_flag);
end

