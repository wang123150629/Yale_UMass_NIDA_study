function[AUC] = one_vs_all_auc(nLabels, membership, scores)

AUC = NaN(1, nLabels);
for l = 1:nLabels
	vector_labels = ones(size(membership)) .* -1;
	vector_labels(membership == l, 1) = 1;
	[junk, junk, junk, AUC(1, l)] = perfcurve(vector_labels, scores(:, l), 1);
end

