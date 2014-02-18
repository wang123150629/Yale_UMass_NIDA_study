function[] = write_to_html(analysis_id, grnd_trth_subject_id, mul_title_str, crf_title_str,...
				mul_confusion_mat, matching_confusion_mat, crf_confusion_mat)

log_dir = get_project_settings('log');
line_str = '';
line_str = strcat(line_str, sprintf('<tr><td>%s</td>', analysis_id));
line_str = strcat(line_str, sprintf('<td>%s</td>', grnd_trth_subject_id));
line_str = strcat(line_str, sprintf('<td>%s</td>', mul_title_str));
line_str = strcat(line_str, sprintf('<td>%0.2f</td>', sum(diag(mul_confusion_mat)) / sum(mul_confusion_mat(:))));
line_str = strcat(line_str, sprintf('<td>%d</td>', sum(mul_confusion_mat(:)) - sum(diag(mul_confusion_mat))));
line_str = strcat(line_str, sprintf('<td>%0.2f</td>', sum(diag(matching_confusion_mat)) / sum(matching_confusion_mat(:))));
line_str = strcat(line_str, sprintf('<td>%d</td>', sum(matching_confusion_mat(:)) - sum(diag(matching_confusion_mat))));
line_str = strcat(line_str, sprintf('<td>%s</td>', crf_title_str));
line_str = strcat(line_str, sprintf('<td>%0.2f</td>', sum(diag(crf_confusion_mat)) / sum(crf_confusion_mat(:))));
line_str = strcat(line_str, sprintf('<td>%d</td></tr>\n</table> </body> </html>',...
		sum(crf_confusion_mat(:)) - sum(diag(crf_confusion_mat))));

text = fileread(fullfile(log_dir, 'log.html'));
text = text(1:end - 25);
fid = fopen(fullfile(log_dir, 'log.html'), 'w');
fprintf(fid, '%s\n%s', text, line_str);
fclose(fid);

