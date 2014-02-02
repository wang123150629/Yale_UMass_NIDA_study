function[] = write_to_html(analysis_id, subject_id, lambda, dictionary, first_baseline_subtract,...
		sparse_code_peaks, variable_window, normalize,...
		add_height, add_summ_diff, add_all_diff, mul_summary_mat, crf_summary_mat,...
		mul_total_errors, crf_total_errors, data_split, dimm, partition_train_set)

log_dir = get_project_settings('log');
if dimm == 1, dim_str = 'w';
else dimm == 2, dim_str = 'a';
end

switch normalize
case 1, normalize = sprintf('%s(-,\\)', dim_str);
case 2, normalize = sprintf('%s(-)', dim_str);
case 3, normalize = sprintf('%s(-)a(\\)', dim_str);
end

switch add_height
case 1, add_height = 'h';
case 2, add_height = 'h,h^2';
end

switch partition_train_set
case 1, partition_train_set = 'T';
case 2, partition_train_set = 'R';
end

line_str = sprintf('<tr><td>%s(%s)</td><td>%s</td><td>%0.4f</td><td>%d</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%0.2f</td><td>%d</td><td>%0.2f</td><td>%d</td></tr>\n</table> </body> </html>',...
		analysis_id, partition_train_set, subject_id, lambda, dictionary,...
		data_split, first_baseline_subtract, sparse_code_peaks, variable_window,...
		normalize,...
		add_height, add_summ_diff, add_all_diff,...
		round_to(mean(mul_summary_mat(:)), 2),...
		mul_total_errors,...
		round_to(mean(crf_summary_mat(:)), 2),...
		crf_total_errors);

text = fileread(fullfile(log_dir, 'log.html'));
text = text(1:end - 25);
fid = fopen(fullfile(log_dir, 'log.html'), 'w');
fprintf(fid, '%s\n%s', text, line_str);
fclose(fid);

