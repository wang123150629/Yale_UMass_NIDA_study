function[] = match_win_exp()

close all;

wins = 1:10;
matching_wqrs_results = NaN(size(wins));
matching_atest_results = NaN(size(wins));

for w = 1:length(wins)
	matching_wqrs_results(w) = sum(diag(build_confusn_matrices('P20_040d_wqrs', wins(w), 1)));
	matching_atest_results(w) = sum(diag(build_confusn_matrices('P20_040d_atest', wins(w), 1)));
end
crf_results = sum(diag(build_confusn_matrices('P20_040d_wqrs', wins(w), 2)));

figure(); set(gcf, 'Position', get_project_settings('figure_size'));
plot(wins, matching_wqrs_results, 'ro-', 'LineWidth', 2); hold on;
plot(wins, matching_atest_results, 'bo-', 'LineWidth', 2);
plot(wins, repmat(crf_results, 1, length(wins)), 'ko-', 'LineWidth', 2);
grid on;
xlabel('Matching Windows');
ylabel('Cumulative Accuracy');
ylim([1, 6]);
set(gca, 'YTick', 1:6);
xlim([1, length(wins)]);
set(gca, 'XTick', 1:length(wins));
temp = strcat(setstr(177), strread(num2str(wins),'%s'));
set(gca, 'XTickLabel', {temp{1:end}});
legend('Matching-wqrs', 'Matching-atest', 'CRF', 'Location', 'SouthEast');
file_name = sprintf('/home/anataraj/NIH-craving/scripts/ecgpuwave_misc/compare_toolboxes');
savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));

