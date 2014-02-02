function[cluster_conf_mat, match_mat] = matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, nLabels, disp_flag)

dummy_var = 7;
cluster_conf_mat = zeros(nLabels, nLabels);

appended_pred_lbl = [pred_l_lbl, repmat(dummy_var, 1, length(grnd_t_lbl))];
appended_grnd_lbl = [grnd_t_lbl, repmat(dummy_var, 1, length(pred_l_lbl))];

adjacency_mat = abs(repmat(grnd_t_loc', 1, length(pred_l_loc)) - repmat(pred_l_loc, length(grnd_t_loc), 1));
assert(isnumeric(adjacency_mat));
dummy_mat = eye(length(grnd_t_loc)) .* (matching_pm + 1);
dummy_mat(dummy_mat == 0) = Inf;
adjacency_mat = [adjacency_mat, dummy_mat];
dummy_mat = eye(length(pred_l_loc)) .* (matching_pm + 1);
dummy_mat(dummy_mat == 0) = Inf;
dummy_mat = [dummy_mat, zeros(length(pred_l_loc), length(grnd_t_loc))];
adjacency_mat = [adjacency_mat; dummy_mat];

[match_mat, cost] = Hungarian(adjacency_mat);
assert(all(sum(match_mat, 1)));
assert(all(sum(match_mat, 2)));

% wiping out the fourth quadrant
temp_mat = ones(size(match_mat));
temp_mat(appended_grnd_lbl == dummy_var, appended_pred_lbl == dummy_var) = 0;
match_mat = match_mat .* temp_mat;
[tar_r, tar_c] = find(match_mat);
appended_grnd_lbl = appended_grnd_lbl(tar_r);
appended_grnd_lbl(appended_grnd_lbl > nLabels) = nLabels;
appended_pred_lbl = appended_pred_lbl(tar_c);
appended_pred_lbl(appended_pred_lbl > nLabels) = nLabels;

for s = 1:length(appended_pred_lbl)
	cluster_conf_mat(appended_grnd_lbl(s), appended_pred_lbl(s)) = cluster_conf_mat(appended_grnd_lbl(s), appended_pred_lbl(s)) + 1;
end

if disp_flag
	fprintf('Ground truth loc: ')
	dispf('%d ', grnd_t_loc)
	fprintf('Predicted loc:    ')
	dispf('%d ', pred_l_loc)

	fprintf('Ground truth: ')
	dispf('%d ', grnd_t_lbl)
	fprintf('Predicted:    ')
	dispf('%d ', pred_l_lbl)

	print_mat(match_mat, appended_grnd_lbl, appended_pred_lbl, 'Predicted');
	print_mat(cluster_conf_mat, 1:nLabels, 1:nLabels, 'Predicted label');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = print_mat(A, row_labels, col_labels, x_str)

nRows = size(A, 1);
nCols = size(A, 2);
assert(nRows == length(row_labels));
assert(nCols == length(col_labels));
label_str = {'P', 'Q', 'R', 'S', 'T', 'U', 'D'};

fprintf('%s-->\n', x_str);
fprintf('   ');
for c = 1:nCols
	fprintf('%s', label_str{col_labels(c)});
end
fprintf('\n');

for r = 1:nRows
	line_to_write = '';
	fprintf(' %s ', label_str{row_labels(r)});
	for c = 1:nCols
		line_to_write = strcat(line_to_write, sprintf('%d', A(r, c)));
	end
	fprintf('%s\n', line_to_write);
end

