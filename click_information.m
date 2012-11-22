function[click_indices, infusion_indices] = click_information(subject_id, behav_mat, display_flag)

click_indices = find(behav_mat(:, 6) == 1);
infusion_indices = find(behav_mat(:, 7) == 1);

if display_flag
	disp(sprintf('Subject = %s', subject_id));
	for c = 1:length(click_indices)
		disp(sprintf('%d:%d %d:%d', behav_mat(click_indices(c), 1), behav_mat(click_indices(c), 2),...
					    behav_mat(click_indices(c), 3), behav_mat(click_indices(c), 4)));
	end
end
