function[] = write_to_html(analysis_id, subject_id, lambda, dictionary, first_baseline_subtract, sparse_code_peaks, variable_window, normalize,...
		add_height, add_summ_diff, add_all_diff, mul_summary_mat, crf_summary_mat, mul_total_errors, crf_total_errors)

log_dir = get_project_settings('log');

line_str = sprintf('<tr><td>%s</td><td>%s</td><td>%0.4f</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%0.2f</td><td>%d</td><td>%0.2f</td><td>%d</td></tr>\n</table> </body> </html>', analysis_id, subject_id, lambda, dictionary,...
		first_baseline_subtract, sparse_code_peaks, variable_window, normalize, add_height, add_summ_diff, add_all_diff,...
		round_to(mean(mul_summary_mat(:)), 2),...
		mul_total_errors,...
		round_to(mean(crf_summary_mat(:)), 2),...
		crf_total_errors);

text = fileread(fullfile(log_dir, 'log.html'));
text = text(1:end - 25);
fid = fopen(fullfile(log_dir, 'log.html'), 'w');
fprintf(fid, '%s\n%s', text, line_str);
fclose(fid);
