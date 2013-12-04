function[] = malai_plots()

close all;
image_format = get_project_settings('image_format');

central = load('/home/anataraj/NIH-craving/results/Malai_zephyr_drift_test/central_slide30_win.mat');
interval1 = [mean(central.pqrst_mat(:, 1:100)) - std(central.pqrst_mat(:, 1:100), [], 1); mean(central.pqrst_mat(:, 1:100)) + std(central.pqrst_mat(:, 1:100), [], 1)];

right = load('/home/anataraj/NIH-craving/results/Malai_zephyr_drift_test/right_slide30_win.mat');
interval2 = [mean(right.pqrst_mat(:, 1:100)) - std(right.pqrst_mat(:, 1:100), [], 1); mean(right.pqrst_mat(:, 1:100)) + std(right.pqrst_mat(:, 1:100), [], 1)];

bottom = load('/home/anataraj/NIH-craving/results/Malai_zephyr_drift_test/bottom_slide30_win.mat');
interval3 = [mean(bottom.pqrst_mat(:, 1:100)) - std(bottom.pqrst_mat(:, 1:100), [], 1); mean(bottom.pqrst_mat(:, 1:100)) + std(bottom.pqrst_mat(:, 1:100), [], 1)];

figure('visible', 'on');
set(gcf, 'Position', get_project_settings('figure_size'));
plot(mean(central.pqrst_mat(:, 1:100)), 'r-', 'LineWidth', 2); hold on;
color = [128,0,0] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval1(1, :), interval1(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

plot(mean(right.pqrst_mat(:, 1:100)), 'b-', 'LineWidth', 2);
color = [0,0,128] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval2(1, :), interval2(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

plot(mean(bottom.pqrst_mat(:, 1:100)), 'g-', 'LineWidth', 2);
color = [0,128,0] ./ 255; transparency = 0.4;
hhh = jbfill(1:100, interval3(1, :), interval3(2, :), color, rand(1, 3), 0, transparency);
hAnnotation = get(hhh, 'Annotation');
hLegendEntry = get(hAnnotation', 'LegendInformation');
set(hLegendEntry, 'IconDisplayStyle', 'off');

xlabel('Waveform features');
ylabel('Millivolts');
grid on;
legend(sprintf('central (%d)', size(central.pqrst_mat, 1)), sprintf('right 2cm (%d)', size(right.pqrst_mat, 1)),...
       sprintf('bottom 2cm (%d)', size(bottom.pqrst_mat, 1)));

file_name = sprintf('/home/anataraj/Desktop/electrode_pos');
% savesamesize(gcf, 'file', file_name, 'format', image_format);
saveas(gcf, file_name, 'pdf');

