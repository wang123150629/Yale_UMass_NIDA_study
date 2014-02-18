function[matching_confusion_mat] = matching_driver2(target_idx, ecg_test_Y, annt, matching_pm, crf_pred_lbl)

ecg_labels = {'P', 'Q', 'R', 'S', 'T', 'U'};
nLabels = numel(ecg_labels);
matching_confusion_mat = zeros(nLabels, nLabels);

cluster_boundaries = [0, find(diff(target_idx) > 100), length(target_idx)];

for c = 2:length(cluster_boundaries)
	grnd_t_loc = target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c));
	grnd_t_lbl = ecg_test_Y(grnd_t_loc);
	pred_l_loc = [];
	pred_l_lbl = [];
	for e = 1:nLabels-1
		entries = getfield(annt, ecg_labels{e});
		puwave_pred = entries >= target_idx(cluster_boundaries(c-1)+1) - (1 * matching_pm) &...
    		              entries <= target_idx(cluster_boundaries(c)) + (1 * matching_pm);
		pred_l_loc = [pred_l_loc, entries(puwave_pred)];
		pred_l_lbl = [pred_l_lbl, repmat(e, 1, sum(puwave_pred))];
	end
	matching_confusion_mat = matching_confusion_mat +...
			       matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, nLabels, false);
end

%{
load(fullfile(pwd, 'ecgpuwave', 'annotations', dispf('P20_040d1_wqrs.mat')));
ecg_mat = ecg_mat(4024660:4024960);
plot(ecg_mat); hold on;
plot(pred_l_loc, ecg_mat(pred_l_loc)-2, 'r*');
plot(grnd_t_loc, ecg_mat(grnd_t_loc)+2, 'go');

temp = [1, 6, Inf, 17, Inf;
	6, 0, Inf, 11, Inf;
	11, 4, Inf, 6, Inf;
	16, 9, Inf, 1, Inf;
	21, 14, Inf, 4, Inf];

temp = [1, 6, Inf, 17, 20, 17, 25;
	6, 1, Inf, 12, 15, 11, 20;
	11, 4, Inf, 7, 10, 6, 15;
	16, 9, Inf, 2, 5, 1, 10;
	21, 14, Inf, 3, 0, 4, 5;
	Inf, Inf, Inf, Inf, Inf, Inf, Inf];

temp = [3, 4, 10, 15, 16, 26, 35, 38, 41;
	8, 1, 5, 10, 11, 21, 30, 33, 36;
	13, 6, 0, 5, 6, 16, 25, 28, 31;
	18, 11, 5, 0, 1, 11, 20, 23, 26;
	23, 16, 10, 5, 4, 6, 15, 18, 21;
	28, 21, 15, 10, 9, 1, 10, 13, 16;
	33, 26, 20, 15, 14, 4, 5, 8, 11];

% tmp = find(annt.T > 4024660); 
% tmp2 = find(annt.T < 4024960);
% annt.T(tmp(1):tmp2(end)) 
% grnd_t = [34    85   130   143   156   162   168   219   259   274];
% pred_l_loc = [5    23    29    34    82   139   156   162   168   216   272   289   294   300];

curr_p = 1;
appended_grnd = [];
appended_grnd_lbl = [];
for g = 1:length(grnd_t_loc)
	inner_loop_executed = false;
	for p = curr_p:length(pred_l_loc)
		inner_loop_executed = true;
		if grnd_t_loc(g) <= pred_l_loc(p) + matching_pm & grnd_t_loc(g) >= pred_l_loc(p) - matching_pm
			appended_grnd(end + 1) = grnd_t_loc(g);
			appended_grnd_lbl(end + 1) = grnd_t_lbl(g);
			curr_p = p + 1;
			break;
		else
			if grnd_t_loc(g) > pred_l_loc(p)
				appended_grnd(end + 1) = pred_l_loc(p) + matching_pm + 1;
				appended_grnd_lbl(end + 1) = dummy_var;
				curr_p = p + 1;
			else
				appended_grnd(end + 1) = grnd_t_loc(g);
				appended_grnd_lbl(end + 1) = grnd_t_lbl(g);
				break;
			end	
		end
	end
	if ~inner_loop_executed
		appended_grnd(end + 1) = grnd_t_loc(g);
		appended_grnd_lbl(end + 1) = grnd_t_lbl(g);
	end
end
if curr_p <= length(pred_l_loc)
	appended_grnd(end+1:end+1+length(pred_l_loc)-curr_p) = pred_l_loc(curr_p:end) + matching_pm + 1;
	appended_grnd_lbl(end+1:end+1+length(pred_l_loc)-curr_p) = dummy_var;
end

curr_g = 1;
appended_pred = [];
appended_pred_lbl = [];
for p = 1:length(pred_l_loc)
	inner_loop_executed = false;
	for g = curr_g:length(grnd_t_loc)
		inner_loop_executed = true;
		if pred_l_loc(p) <= grnd_t_loc(g) + matching_pm & pred_l_loc(p) >= grnd_t_loc(g) - matching_pm
			appended_pred(end + 1) = pred_l_loc(p);
			appended_pred_lbl(end + 1) = pred_l_lbl(p);
			curr_g = g + 1;
			break;
		else
			if pred_l_loc(p) > grnd_t_loc(g)
				appended_pred(end + 1) = grnd_t_loc(g) + matching_pm + 1;
				appended_pred_lbl(end + 1) = dummy_var;
				curr_g = g + 1;
			else
				appended_pred(end + 1) = pred_l_loc(p);
				appended_pred_lbl(end + 1) = pred_l_lbl(p);
				break;
			end	
		end
	end
	if ~inner_loop_executed
		appended_pred(end + 1) = pred_l_loc(p);
		appended_pred_lbl(end + 1) = pred_l_lbl(p);
	end
end
if curr_g <= length(grnd_t_loc)
	appended_pred(end+1:end+1+length(grnd_t_loc)-curr_g) = grnd_t_loc(curr_g:end) + matching_pm + 1;
	appended_pred_lbl(end+1:end+1+length(grnd_t_loc)-curr_g) = dummy_var;
end

fprintf('Appended ground truth: ')
dispf('%d ', appended_grnd)
fprintf('Appended predicted:    ')
dispf('%d ', appended_pred)
fprintf('Appended ground label:    ')
dispf('%d ', appended_grnd_lbl)
fprintf('Appended predicted label: ')
dispf('%d ', appended_pred_lbl)
%}
% assert(all(appended_pred <= appended_grnd + matching_pm & appended_pred >= appended_grnd - matching_pm));
% assert(all(appended_grnd <= appended_pred + matching_pm & appended_grnd >= appended_pred - matching_pm));

%{
load(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('P20_040d1_wqrs.mat')));
ecg_mat = ecg_mat(4024660:4024960);
plot(ecg_mat); hold on;
plot(pred_l_loc-4024659, ecg_mat(pred_l_loc-4024659)-2, 'r*');
plot(grnd_t_loc-4024659, ecg_mat(grnd_t_loc-4024659)+2, 'go');
grnd_t_loc = [           34, 85, 130, 143, 156, 162, 168, 219, 259, 274];
pred_l_loc = [5, 23, 29, 34, 82,      139, 156, 162, 168, 216,      272, 289, 294, 300];
%}

%{
grnd_t_loc = [4024693,   4024744,   4024789,   4024802,   4024815,   4024821,   4024827,   4024878,   4024918,   4024933]; % - 4024659;
grnd_t_lbl = [4, 5, 6, 1, 2, 3, 4, 5, 6, 4];
%pred_l_loc = [4024664,   4024682,   4024688,   4024693,   4024741,   4024798,   4024815,   4024821,   4024827,   4024875,   4024931	  4024948,   4024953,   4024959]; % - 4024659;
pred_l_loc = [4024688,   4024693,   4024741,   4024798,   4024815,   4024821,   4024827,   4024875,   4024931];
pred_l_lbl = [3, 4, 5, 1, 2, 3, 4, 5, 1];
matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, false)
%}

%{
ecg_mat_cluster = ecg_mat(target_idx(cluster_boundaries(c-1)+1) - (1 * matching_pm):...
		  target_idx(cluster_boundaries(c)) + (1 * matching_pm));
offset = target_idx(cluster_boundaries(c-1)+1) - (1 * matching_pm) - 1;
plot(ecg_mat_cluster); hold on;
text(pred_l_loc-offset, ecg_mat_cluster(pred_l_loc-offset)-5, {pred_l_lbl}, 'color', 'r');
text(grnd_t_loc-offset, ecg_mat_cluster(grnd_t_loc-offset)+5, {ecg_test_Y(grnd_t_loc)}, 'color', 'g');
tempp_lbl = crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c)));
tempp_loc = grnd_t_lbl ~= tempp_lbl;
text(grnd_t_loc(tempp_loc) - offset, ecg_mat_cluster(grnd_t_loc(tempp_loc) - offset)+10,...
				{crf_pred_lbl(grnd_t_loc(tempp_loc))}, 'color', 'k');
find(grnd_t_lbl ~= crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c))))

crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c)))
holdd = crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c)));
find(grnd_t_lbl ~= crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c))))
holdd(find(grnd_t_lbl ~= crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c)))))
grnd_t_loc(grnd_t_lbl ~= crf_pred_lbl(target_idx(cluster_boundaries(c-1)+1:cluster_boundaries(c))))
keyboard
close all
%}

