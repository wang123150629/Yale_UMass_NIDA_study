function[] = cocaine_subj(record_no, annotation_file)

% cocaine_subj('P20_040', 'wqrs')
% cocaine_subj('sel100', 'atr')

%{
1. make_csv_for_puwave() creates a .csv file which can be fed into ECGPUWave EPS Ltd C version to get annotation file atest. For P20_040d I have already created the csv file
2. Create .dat and .hea file by running wrsamp -F 250 -i P20_040d.csv -o P20_040d 0
3. Update subject Id in zephyr_easytest.c file
4. Complie it as gcc -o zephyr zephyr_easytest.c qrsdet.o bdac.o classify.o rythmchk.o noisechk.o match.o postclas.o analbeat.o qrsfilt.o -lwfdb -lcurl
5. Run it as ./zephyr
6. At the end of step 4 you should be having a atest file which can be used in the code below
7. Run display_mit_peaks for an overlay of CRF vs ECGPU label assignments
%}

% make_csv_for_puwave();

nTotal_clusters = 20;
matching_pm = 4;
record_type = 0;
matlab_label_assgnmnts = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, annotation_file, record_type);

mit_bih_peaks = struct();
mit_bih_peaks.annt = matlab_label_assgnmnts;

peak_thres = 10;
[junk, ecg_mat, junk] = textread(sprintf('ecgpuwave/osea20-gcc/%s.csv', record_no), '%d %d %d');
[maxtab, mintab] = peakdet(ecg_mat, peak_thres);
assert(isempty(intersect(maxtab(:, 1), mintab(:, 1))));
candidate_peaks = [maxtab(:, 1)', mintab(:, 1)'];

ground_truth = [mit_bih_peaks.annt.P, mit_bih_peaks.annt.Q, mit_bih_peaks.annt.R, mit_bih_peaks.annt.S, mit_bih_peaks.annt.T];
ground_truth_labels = [repmat(1, size(mit_bih_peaks.annt.P)),...
		       repmat(2, size(mit_bih_peaks.annt.Q)),...
		       repmat(3, size(mit_bih_peaks.annt.R)),...
		       repmat(4, size(mit_bih_peaks.annt.S)),...
		       repmat(5, size(mit_bih_peaks.annt.T))];

a = sort(candidate_peaks);
all_cand_points = [];
tc = 1;
while tc <= nTotal_clusters
	candidate_location = randi([1, length(a)-15], 1);
	candidate_win = randi([15, 25], 1);
	candidate_points = a(candidate_location:candidate_location + candidate_win-1);

	if tc == 1
		all_cand_points = [all_cand_points, candidate_points];
		tc = tc + 1;
	else
		if sum(diff(sort([all_cand_points, candidate_points])) > 100) == tc-1
			all_cand_points = [all_cand_points, candidate_points];
			pred_l_loc = candidate_points;
			grnd_tar_idx = find(ground_truth >= candidate_points(1) - matching_pm * 1 &...
				            ground_truth <= candidate_points(end) + matching_pm * 1);
			grnd_t_loc = ground_truth(grnd_tar_idx);
			grnd_t_lbl = ground_truth_labels(grnd_tar_idx);
			pred_l_lbl = ones(size(pred_l_loc)) .* 6;
			[junk, match_mat] = matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, 6, false);

			[tar_r, tar_c] = find(match_mat);
			valid_rows = tar_r <= length(grnd_t_lbl) & tar_c <= length(pred_l_lbl);
			pred_l_lbl(tar_c(valid_rows)) = grnd_t_lbl(tar_r(valid_rows));

			plot(ecg_mat, 'b'); hold on
			text(grnd_t_loc, ecg_mat(grnd_t_loc)-10, {grnd_t_lbl}, 'color', 'r');
			text(pred_l_loc, ecg_mat(pred_l_loc)+10, {pred_l_lbl}, 'color', 'g');
			xlim([grnd_t_loc(1), grnd_t_loc(end)]);
			keyboard
			tc = tc + 1;
		end
	end
end

matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, nLabels, disp_flag)

keyboard


a_candidates(a_cand_locations(tr))
a_candidates = find(diff(a) > 50);
a_cand_locations = randperm(length(a_candidates));
shuffled_a = randperm(length(a));

plot(ecg_mat, 'b-'); hold on;
plot(maxtab(:, 1), maxtab(:, 2), 'ro');
plot(mintab(:, 1), mintab(:, 2), 'go');
plot(a, ecg_mat(a), 'ko');

matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, nLabels, disp_flag)

save(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s_%s.mat', record_no, annotation_file)), '-struct', 'mit_bih_peaks');

%{
mit_bih_peaks = struct();
if exist(fullfile(dirsig, sprintf('%s.csv', ecgnr)))
	ecg_mat = csvread(fullfile(dirsig, sprintf('%s.csv', ecgnr)));
else
	[junk, ecg_mat, junk] = textread(fullfile(dirsig, sprintf('%s.txt', ecgnr)), '%d\t%d\t%d');
end
mit_bih_peaks.ecg_mat = ecg_mat';

mit_bih_peaks.annt = annt;
save(fullfile(pwd, 'ecgpuwave', 'annotations', sprintf('%s_%s.mat', ecgnr, anot)), '-struct', 'mit_bih_peaks');
%}
