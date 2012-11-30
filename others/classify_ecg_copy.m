function[] = classify_ecg()

close all;

global write_dir
write_dir = fullfile(pwd, 'plots');
global image_format
image_format = 'png';
global subject_id;

% get the interpolated ECG for the target sessions
interpolated_ecg = get_raw_ecg_data_per_dose();
close all;

% Removing the labels
ecg_x = interpolated_ecg(:, 1:end-1);
ecg_x = bsxfun(@minus, ecg_x, mean(ecg_x));

% PCA on the whole training set
[PC, score, latent] = princomp(ecg_x);
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
plot(log(latent));
xlabel('Principal components'); ylabel('log(eigenvalues)'); title(sprintf('PCA on interpolated ECG b/w RR'));
file_name = sprintf('%s/subj_%s_rr_pca', write_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

% Build design matrix with top k features
top_how_many = 180;
ecg_x = ecg_x * PC(:, 1:top_how_many);
% Adding the labels back
ecg_x = [ecg_x, interpolated_ecg(:, end)];

nRuns = 10;
tr_percent = 80; % training data size in percentage
accuracy_classes = zeros(3, 10);
% classes: 1 - baseline, 2 - 8mg, 3 - 16mg, 4 - 32mg
classes = [1, 2; 1, 3; 1, 4];
for r = 1:nRuns
	for c = 1:size(classes, 1)
		accuracy_classes(c, r) = partition_and_classify(ecg_x, classes(c, :), tr_percent);
	end
end
accuracy_classes = [accuracy_classes, mean(accuracy_classes, 2)];

keyboard

figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
bar(accuracy_classes);
xlabel('Analysis'); ylabel('Accuracies');
title(sprintf('Logistic regression performance\n10 runs + average'));
set(gca, 'XTickLabel', {'base vs. 8mg', 'base vs. 16mg', 'base vs. 32mg'});
file_name = sprintf('%s/subj_%s_log_reg_perf', write_dir, subject_id);
savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[accuracy] = partition_and_classify(ecg_x, classes, tr_percent)

complete_train_set = [];
complete_test_set = [];
for c = 1:length(classes)
	[train_set, test_set] = fetch_training_instances(classes(c), ecg_x, tr_percent);
	complete_train_set = [complete_train_set; train_set];
	complete_test_set = [complete_test_set; test_set];
end

% change labels
unique_labels = unique(complete_train_set(:, end));
assert(length(unique_labels) == 2);
% Reassigning the labels to 0 and 1 for logistic regression
complete_train_set(find(unique_labels(1) == complete_train_set(:, end)), end) = 0;
complete_train_set(find(unique_labels(2) == complete_train_set(:, end)), end) = 1;
complete_test_set(find(unique_labels(1) == complete_test_set(:, end)), end) = 0;
complete_test_set(find(unique_labels(2) == complete_test_set(:, end)), end) = 1;
% Fitting betas using glmfit
betas = glmfit(complete_train_set(:, 1:end-1), complete_train_set(:, end), 'binomial')';

% Adding ones to the test set since there is an intercept term that comes from glmfit
intercept_added_test_set = complete_test_set(:, 1:end-1)';
intercept_added_test_set = [ones(1, size(intercept_added_test_set, 2)); intercept_added_test_set];
z = betas * intercept_added_test_set;
pos_class_prob = 1 ./ (1 + exp(-z));
neg_class_prob = 1 - pos_class_prob;
likelihood_ratio = neg_class_prob ./ pos_class_prob;
class_guessed = ones(1, size(intercept_added_test_set, 2));
class_guessed(find(likelihood_ratio > 1)) = 0;
accuracy = sum(class_guessed == complete_test_set(:, end)') * 100 / size(complete_test_set, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[train_set, test_set] = fetch_training_instances(class, ecg_x, tr_percent)

target_idx = find(ecg_x(:, end) == class);
all_samples = target_idx(randperm(length(target_idx)));
tr_percent = round_to(tr_percent * length(all_samples) / 100, 0);
train_samples = all_samples(1:tr_percent);
test_samples = setdiff(all_samples, train_samples);
assert(isempty(intersect(train_samples, test_samples)));
train_set = ecg_x(train_samples, :);
test_set = ecg_x(test_samples, :);
dispf(sprintf('class=%d no. of train samples=%d', class, size(train_set, 1)));
dispf(sprintf('class=%d no. of test samples=%d', class, size(test_set, 1)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[interpolated_ecg] = get_raw_ecg_data_per_dose()

global write_dir;
global image_format;

root_dir = pwd;
data_dir = fullfile(root_dir, 'data');
global subject_id
subject_id = 'P20_048';
subject_session = '2012_08_17-10_15_55';

time_resolution = 60; % seconds
% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_summary_clean.csv', subject_session)), 1, 0);
% Loading the behavior data
behav_mat = csvread(fullfile(data_dir, subject_id, sprintf('%s_behav.csv', subject_id)), 1, 0);
% Fetching the absolute and event indices
index_maps = find_start_end_time(summary_mat, behav_mat, time_resolution);

% Loading the raw ECG data
% The raw ECG data is sampled every 4 milliseconds so for every 250 (250 x 4 = 1000 = 1 second) samples we will have an entry in the summary table. Now the summary table has entries for sec1.440 i.e. sec1.440 to sec2.436 are summarized into this entry.
ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);

dosage_levels = [-3, 8, 16, 32];
interpolated_ecg = [];
for d = 1:length(dosage_levels)
	disp(sprintf('dosage=%d', dosage_levels(d)));

	% For the d mg infusion ONLY in the first session, fetch the associated indices from the absolute time axis. For instance this fetches 11100:60:12660 = 27 time points
	dosg_start_end = find(behav_mat(:, 6) == dosage_levels(d));
	if dosage_levels(d) < 0
		sess_start_end = find(behav_mat(:, 5) == 0);
		title_str = sprintf('session=1, baseline');
	else
		sess_start_end = find(behav_mat(:, 5) == 1);
		title_str = sprintf('session=1, dosage=%d', dosage_levels(d));
	end
	dosg_sess_start_end = intersect(dosg_start_end, sess_start_end);
	disp(sprintf('Behav: %d:%d -- %d:%d', behav_mat(dosg_sess_start_end(1), 3),...
		behav_mat(dosg_sess_start_end(1), 4),...
		behav_mat(dosg_sess_start_end(end), 3), behav_mat(dosg_sess_start_end(end), 4)));
	behav_start_end_times = intersect(index_maps.behav(dosg_start_end), index_maps.behav(sess_start_end));

	% Now this subtracts 11100 - 8154 which gives 2946. This is telling us that the 2946th time point in the summary file corresponds to the d mg, first session.
	summ_start_time = behav_start_end_times(1) - (index_maps.summary(1)-1);
	% Similarly for the end time point it is 12720 - 8155 = 4565th time point
	summ_end_time = behav_start_end_times(end)+60 - index_maps.summary(1);
	disp(sprintf('Summ: %d:%d:%0.3f -- %d:%d:%0.3f', summary_mat(summ_start_time, 4),...
		summary_mat(summ_start_time, 5), summary_mat(summ_start_time, 6),...
		summary_mat(summ_end_time, 4), summary_mat(summ_end_time, 5), summary_mat(summ_end_time, 6)));
	% Checking if the length of the extracted segments based on the time points is the same as the start_end time vector. The key is to understand that the summary and absolute tim axis are in the same resolution i.e. 60 one sample per second
	assert(length(summ_start_time:60:summ_end_time) == length(behav_start_end_times));

	% Now we need to jump from 60 second resolution to 250 samples per second resolution. This takes the start time 
	raw_start_time = (summ_start_time - 1) * 250 + 1;
	raw_end_time = (summ_end_time - 1) * 250 + 1;
	disp(sprintf('Raw ECG: %d:%d:%0.3f -- %d:%d:%0.3f', ecg_mat(raw_start_time, 4),...
		ecg_mat(raw_start_time, 5), ecg_mat(raw_start_time, 6),...
		ecg_mat(raw_end_time, 4), ecg_mat(raw_end_time, 5), ecg_mat(raw_end_time, 6)));

	x = ecg_mat(raw_start_time:raw_end_time, 7);
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	plot(x, 'b-');
	xlabel('Time(milliseconds)'); ylabel('microvolts'); title(sprintf('%s, raw ECG', title_str));
	file_name = sprintf('%s/subj_%s_dos_%d_raw_chunk', write_dir, subject_id, d);
	savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

	[rr, rs] = rrextract(x, 250, 0.1);
	rr_start_end = [rr(1:end-1); rr(2:end)-1]';
	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	hold_flag = true;
	for s = 1:size(rr_start_end, 1)
		if (rr_start_end(s, 2) - rr_start_end(s, 1)) > 200 & (rr_start_end(s, 2) - rr_start_end(s, 1)) <= 300
			plot(x(rr_start_end(s, 1):rr_start_end(s, 2)), 'r-');
			if hold_flag, hold on; hold_flag = false; end
			x_length = 1:length(x(rr_start_end(s, 1):rr_start_end(s, 2)));
			xi = 1:1:200;
			interpol_data = interp1(x_length, x(rr_start_end(s, 1):rr_start_end(s, 2)), xi, 'pchip');
			if max(interpol_data) < 5000 & min(interpol_data) >= 0
				interpolated_ecg = [interpolated_ecg; interpol_data, d];
			else
				keyboard
			end
		end
	end
	plot(repmat(200, 1, 501), 0:500, 'k*');
	plot(repmat(300, 1, 501), 0:500, 'k*');
	xlabel('Time(milliseconds)'); ylabel('microvolts'); title(sprintf('%s, raw ECG b/w RR', title_str));
	file_name = sprintf('%s/subj_%s_dos_%d_raw_rr', write_dir, subject_id, d);
	savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));

	figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
	hold_flag = true;
	plot_idx = find(interpolated_ecg(:, end) == d);
	for s = 1:length(plot_idx)
		plot(interpolated_ecg(plot_idx(s), 1:end-1), 'g-');
		if hold_flag, hold on; hold_flag = false; end
	end
	plot(mean(interpolated_ecg(plot_idx, 1:end-1)), 'k-', 'LineWidth', 2);
	xlabel('Time(milliseconds)'); ylabel('microvolts'); title(sprintf('%s, interpolated ECG b/w RR', title_str));
	file_name = sprintf('%s/subj_%s_dos_%d_rr_inter', write_dir, subject_id, d);
	savesamesize(gcf, 'file', file_name, 'format', sprintf('-d%s', image_format));
end

% raw_ecg_per_dose = cell(1, length(dosage_levels));
% raw_ecg_per_dose{1, d} = [ecg_mat(raw_start_time:raw_end_time, 7)];
%{
p=100;r=rand(1,p);x=2*r-1;y=r+2;z=3-r;
scatter3(x,y,z,3*ones(1,p),2*[1:p]/p-1);view(-30,10);
x=x-mean(x);y=y-mean(y);z=z-mean(z);
A=[x;y;z];[U,S,V]=svds(A);
hold on;
scatter3(x,y,z,3*ones(1,p),U(:,1)'*A);

[U, S, V] = svds(interpolated_ecg(:, 1:250), 200);
figure(); bar(diag(log(S)));
xlabel('Count');
ylabel('log(singular values)');
title('Interpolated ECG, 200 singular values, log scale');

ipol_svd_ecg = zeros(size(interpolated_ecg, 1), top_how_many);
for i = 1:top_how_many
	ipol_svd_ecg = ipol_svd_ecg + (S(i, i) .* (U(:, i) * V(:, i)'));
end
cutoff_freq = linspace(0.01, 0.99, 1000);
perf = zeros(1000, 4);
for i=1:1000
	yhat = fz > cutoff_freq(i);
	w = complete_test_set(:, end) == 1;
	sensitivity = mean(yhat(w) == 1); 
	specificity = mean(yhat(~w) == 0); 
	c_rate = mean(complete_test_set(:, end) == yhat'); 
	d = [sensitivity, specificity] - [1, 1];
	d = sqrt(d(1)^2 + d(2)^2); 
	perf(i, :) = [sensitivity, specificity, c_rate, d];
	keyboard
end

figure();
plot(cutoff_freq, perf(:, 1), 'b-'); hold on;
plot(cutoff_freq, perf(:, 2), 'r-');
plot(cutoff_freq, perf(:, 3), 'k-');
plot(cutoff_freq, perf(:, 4), 'g-');

keyboard
%}

