function[] = plot_complexes_hr_bins(complete_train_set, complete_test_set, class_hr_to_plot, class_label, hr_bins, subject_id, nBins)

plot_dir = get_project_settings('plots');
image_format = get_project_settings('image_format');

class1_tr = complete_train_set(:, end) == -1;
class2_tr = complete_train_set(:, end) == 1;
class1_ts = complete_test_set(:, end) == -1;
class2_ts = complete_test_set(:, end) == 1;

interval1 = [mean(complete_train_set(class1_tr, 1:end-1), 1) - std(complete_train_set(class1_tr, 1:end-1), [], 1); mean(complete_train_set(class1_tr, 1:end-1), 1) + std(complete_train_set(class1_tr, 1:end-1), [], 1)];

interval2 = [mean(complete_train_set(class1_ts, 1:end-1), 1) - std(complete_train_set(class1_ts, 1:end-1), [], 1); mean(complete_train_set(class1_ts, 1:end-1), 1) + std(complete_train_set(class1_ts, 1:end-1), [], 1)];

interval3 = [mean(complete_train_set(class2_tr, 1:end-1), 1) - std(complete_train_set(class2_tr, 1:end-1), [], 1); mean(complete_train_set(class2_tr, 1:end-1), 1) + std(complete_train_set(class2_tr, 1:end-1), [], 1)];

interval4 = [mean(complete_train_set(class2_ts, 1:end-1), 1) - std(complete_train_set(class2_ts, 1:end-1), [], 1); mean(complete_train_set(class2_ts, 1:end-1), 1) + std(complete_train_set(class2_ts, 1:end-1), [], 1)];

figure('visible', 'off');
set(gcf, 'Position', get_project_settings('figure_size'));

subplot(2, 3, [1, 2, 4, 5]);
color = [0,0,128] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval1(1, :), interval1(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');
hold on;

color = [128,0,0] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval2(1, :), interval2(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

color = [128,128,128] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval3(1, :), interval3(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

color = [0,128,0] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval4(1, :), interval4(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

plot(mean(complete_train_set(class1_tr, 1:end-1), 1), 'b-', 'LineWidth', 2);
plot(mean(complete_test_set(class1_ts, 1:end-1), 1), 'r-', 'LineWidth', 2);
plot(mean(complete_train_set(class2_tr, 1:end-1), 1), 'k-', 'LineWidth', 2);
plot(mean(complete_test_set(class2_ts, 1:end-1), 1), 'g-', 'LineWidth', 2);

grid on;

legend(sprintf('Train %s(%d)', class_label{1}, sum(class1_tr)), sprintf('Test %s(%d)', class_label{1}, sum(class1_ts)),...
       sprintf('Train %s(%d)', class_label{2}, sum(class2_tr)), sprintf('Test %s(%d)', class_label{2}, sum(class2_ts)));
xlabel('Waveform features'); ylabel('Normalized millivolts');
title(sprintf('%s, %s vs. %s; HR: %d-%d', get_project_settings('strrep_subj_id', subject_id), class_label{1}, class_label{2},...
						hr_bins(1), hr_bins(2)));

hr_min = min(reshape(cell2mat(class_hr_to_plot), [], 1));
hr_max = max(reshape(cell2mat(class_hr_to_plot), [], 1));

subplot(2, 3, 3);
hist(class_hr_to_plot{1});
h = findobj(gca, 'Type', 'patch');
set(h(1), 'FaceColor', [166, 42, 42] ./ 255, 'EdgeColor', 'w');
xlim([hr_min, hr_max]);
xlabel(sprintf('%s HR', class_label{1}));
ylabel('count');

subplot(2, 3, 6);
hist(class_hr_to_plot{2})
h = findobj(gca, 'Type', 'patch');
set(h(1), 'FaceColor', [46, 139, 87] ./ 255, 'EdgeColor', 'w');
xlim([hr_min, hr_max]);
xlabel(sprintf('%s HR', class_label{2}));
ylabel('count');

file_name = sprintf('%s/%s/%s_waveforms_%dbins_%d_%d_%s', plot_dir, subject_id, subject_id, nBins, hr_bins(1), hr_bins(2), class_label{2});
savesamesize(gcf, 'file', file_name, 'format', image_format);

