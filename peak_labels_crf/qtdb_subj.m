function[] = qtdb_subj(record_no)

% qtdb_subj('sel100')

results_dir = get_project_settings('results');
annotations_dir = get_project_settings('annotations');
clusters_apart = get_project_settings('clusters_apart');

peak_thres = 10;
nTotal_clusters = 200;
min_peaks = 10;
max_peaks = 10;
matching_pm = 4;

% MIT BIH or Siemens, etc
record_type = 0;
dummy_var = 6;
nWins = 1;
tc = 1;
ecg_labels = {'P', 'Q', 'R', 'S', 'T'};
nPeaks = numel(ecg_labels);

grnd_annotation_file = 'atr';
test_annotation_file = 'wqrs';

% Use annotations and get peak labels
% Verified that the annotations wqrs as well as limits are both referring to the same signal/lead

if exist(fullfile('ecgpuwave/osea20-gcc', sprintf('nsrdb_%s.mat', record_no)))
	load(fullfile('ecgpuwave/osea20-gcc', sprintf('nsrdb_%s.mat', record_no)));
else
	matlab_label_assgnmnts = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, grnd_annotation_file, record_type);
	[junk, ecg_mat, junk] = textread(sprintf('ecgpuwave/osea20-gcc/%s.csv', record_no), '%d %d %d');
	[maxtab, mintab] = peakdet(ecg_mat, peak_thres);
	nsrdb_info = struct();
	nsrdb_info.matlab_label_assgnmnts = matlab_label_assgnmnts;
	nsrdb_info.ecg_mat = ecg_mat;
	nsrdb_info.maxtab = maxtab;
	nsrdb_info.mintab = mintab;
	save(fullfile('ecgpuwave/osea20-gcc', sprintf('nsrdb_%s.mat', record_no)), '-struct', 'nsrdb_info');
end

keyboard

ground_truth_locations = [matlab_label_assgnmnts.P, matlab_label_assgnmnts.Q, matlab_label_assgnmnts.R,...
			  matlab_label_assgnmnts.S, matlab_label_assgnmnts.T];
ground_truth_labels = [repmat(1, size(matlab_label_assgnmnts.P)),...
		       repmat(2, size(matlab_label_assgnmnts.Q)),...
		       repmat(3, size(matlab_label_assgnmnts.R)),...
		       repmat(4, size(matlab_label_assgnmnts.S)),...
		       repmat(5, size(matlab_label_assgnmnts.T))];
[ground_truth_locations, sorted_idx] = sort(ground_truth_locations);
ground_truth_labels = ground_truth_labels(sorted_idx);

assert(isempty(intersect(maxtab(:, 1), mintab(:, 1))));
candidate_peaks = [maxtab(:, 1)', mintab(:, 1)'];
sorted_candidate_peaks = sort(candidate_peaks);
labeled_peaks = [ecg_mat'; zeros(2, length(ecg_mat))];
labeled_peaks(2, sorted_candidate_peaks) = ecg_mat(sorted_candidate_peaks);
labeled_peaks(3, sorted_candidate_peaks) = 100;

all_cand_points = [];

while tc <= nTotal_clusters
	grnd_t_loc = [];
	grnd_t_lbl = [];
	pred_l_loc = [];
	pred_l_lbl = [];

	candidate_location = randi([1, length(ground_truth_locations)-max_peaks], 1);
	candidate_win = randi([min_peaks, max_peaks], 1);
	candidate_points = ground_truth_locations(candidate_location:candidate_location + candidate_win-1);

	gap_in_peaks = find(diff(candidate_points) > clusters_apart);
	if ~isempty(gap_in_peaks)
		candidate_points = candidate_points(1:gap_in_peaks);
	end

	% atleast 100 units away
	if tc == 1
		grnd_t_loc = candidate_points;
	elseif sum(diff(sort([all_cand_points, candidate_points])) > clusters_apart) == tc-1
		grnd_t_loc = candidate_points;
	end

	if ~isempty(grnd_t_loc)
		grnd_tar_idx = find(ground_truth_locations >= min(grnd_t_loc) &...
				    ground_truth_locations <= max(grnd_t_loc));
		grnd_t_lbl = ground_truth_labels(grnd_tar_idx);
	end

	% Each peak should appear twice and should lie atleast 5000 units from the start and end points
	if ~isequal(sort(repmat(1:nPeaks, 1, 2)), sort(grnd_t_lbl)) |...
	    (min(grnd_t_loc) <= 5000 & max(grnd_t_loc) >= length(ecg_mat, 1) - 5000)
		grnd_t_loc = [];
		grnd_t_lbl = [];
	end

	if ~isempty(grnd_t_loc) & ~isempty(grnd_t_lbl)
		pred_tar_idx = find(sorted_candidate_peaks >= min(grnd_t_loc) - (matching_pm * nWins) &...
			            sorted_candidate_peaks <= max(grnd_t_loc) + (matching_pm * nWins));
		pred_l_loc = sorted_candidate_peaks(pred_tar_idx);
		pred_l_lbl = ones(size(pred_l_loc)) .* dummy_var;

		[junk, match_mat] = matching(grnd_t_loc, pred_l_loc, grnd_t_lbl, pred_l_lbl, matching_pm, nPeaks+1, false);

		[tar_r, tar_c] = find(match_mat);
		of_interest_entries = tar_r <= length(grnd_t_loc) & tar_c <= length(pred_l_loc);
		pred_l_lbl(tar_c(of_interest_entries)) = grnd_t_lbl(tar_r(of_interest_entries));
		labeled_peaks(3, pred_l_loc) = pred_l_lbl;
		all_cand_points = [all_cand_points, pred_l_loc];
		tc = tc + 1;

		assert(sum(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100) == length(all_cand_points));

		%{
		plot(ecg_mat, 'b'); hold on
		text(grnd_t_loc, ecg_mat(grnd_t_loc)-10, {grnd_t_lbl}, 'color', 'r');
		text(pred_l_loc, ecg_mat(pred_l_loc)+10, {pred_l_lbl}, 'color', 'g');
		xlim([min([grnd_t_loc, pred_l_loc]), max([grnd_t_loc, pred_l_loc])]);
		keyboard
		close all
		%}
	end
end
assert(sum(labeled_peaks(3, :) > 0) == length(candidate_peaks));
assert(sum(labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100) == length(all_cand_points));
assert(sum(labeled_peaks(3, :) == 100) == length(candidate_peaks) - length(all_cand_points));

peaks_information = struct();
peaks_information.labeled_peaks = labeled_peaks;
peaks_information.time_matrix = [];
save(fullfile(results_dir, 'labeled_peaks', sprintf('%s_%s_grnd_trth.mat', record_no, grnd_annotation_file)),...
				'-struct', 'peaks_information');

mit_bih_peaks = struct();
mit_bih_peaks.annt = matlab_label_assgnmnts2;
save(fullfile(annotations_dir, sprintf('%s_%s.mat', record_no, test_annotation_file)), '-struct', 'mit_bih_peaks');

dispf('Peaks | %s counts | %s counts | hits', grnd_annotation_file, test_annotation_file);
for e = 1:nPeaks
	entries = getfield(matlab_label_assgnmnts, ecg_labels{e});
	entries2 = getfield(matlab_label_assgnmnts2, ecg_labels{e});
	dispf('%s | %d | %d | %d', ecg_labels{e}, sum(~isnan(entries)), sum(~isnan(entries2)), length(intersect(entries, entries2)));
end

%{
% Applies only to cocaine subject
1. make_csv_for_puwave() creates a .csv file which can be fed into ECGPUWave EPS Ltd C version to get annotation file atest. For P20_040 I have already created the csv file
2. Create .dat and .hea file by running wrsamp -F 250 -i P20_040d.csv -o P20_040d 0
3. Update subject Id in zephyr_easytest.c file
4. Complie it as gcc -o zephyr zephyr_easytest.c qrsdet.o bdac.o classify.o rythmchk.o noisechk.o match.o postclas.o analbeat.o qrsfilt.o -lwfdb -lcurl
5. Run it as ./zephyr
6. At the end of step 4 you should be having a atest file which can be used in the code below
7. Run display_mit_peaks for an overlay of CRF vs ECGPU label assignments
%}

% make_csv_for_puwave();
% matlab_label_assgnmnts2 = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, test_annotation_file, record_type);

