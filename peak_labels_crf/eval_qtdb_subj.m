function[] = eval_qtdb_subj(record_no)

% 1. Download the subject's data from qtdb by running /home/anataraj/NIH-craving/ecgpuwave/osea20-gcc/fetch_records.sh sel100
% 2. This should result in five files per subject viz sel100.atr  sel100.dat  sel100.hea  sel100.pu0  sel100_ann.csv. This last file is a copy of .pu0 in csv format
% 3. Get the Matlab code, qtdb_subj(record_no), to label all peaks
% 4. This code also generates a plot of accuracy as a function of window size +/-1, +/-2, etc 

close all;

annotation_file = 'atr';
record_type = 0;
matlab_label_assgnmnts = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, annotation_file, record_type);

ecgpuwave_peak_locations{1} = [matlab_label_assgnmnts.P(~isnan(matlab_label_assgnmnts.P))];
ecgpuwave_peak_locations{2} = [matlab_label_assgnmnts.fiducial(~isnan(matlab_label_assgnmnts.fiducial))];
ecgpuwave_peak_locations{3} = sort([matlab_label_assgnmnts.T(~isnan(matlab_label_assgnmnts.T)),...
				    matlab_label_assgnmnts.T2(~isnan(matlab_label_assgnmnts.T2))]);

if ~isempty(ecgpuwave_peak_locations{1}) & ~isempty(ecgpuwave_peak_locations{2}) & ~isempty(ecgpuwave_peak_locations{3})
	[f1, f2, f3, f4, f5, f6] = textread(sprintf('/home/anataraj/NIH-craving/ecgpuwave/osea20-gcc/%s_ann.csv', record_no),...
													'%s\t%d\t%s\t%d\t%d\t%d');
	assert(length(unique(f3)) == 5);

	annotations_to_compare = {'p', 'N', 't'};
	nAnnotations = length(annotations_to_compare);
	plus_minus_windows = [1:10];
	label_matches = NaN(nAnnotations, length(plus_minus_windows)+1);
	plot_str = {'ro-', 'bo-', 'go-'};
	legend_str = {'P', 'QRS', 'T/T2'};

	figure(); set(gcf, 'Position', get_project_settings('figure_size'));
	for i = 1:nAnnotations
		assert(min(diff(ecgpuwave_peak_locations{i})) > max(plus_minus_windows));
		target_idx = find(strcmp(annotations_to_compare{i}, f3));

		label_matches(i, 1) = length(intersect(f2(target_idx), ecgpuwave_peak_locations{i}));
		for j = 1:length(plus_minus_windows)
			label_matches(i, j+1) = length(intersect(f2(target_idx), ecgpuwave_peak_locations{i}+plus_minus_windows(j))) +...
						length(intersect(f2(target_idx), ecgpuwave_peak_locations{i}-plus_minus_windows(j))) +...
						label_matches(i, j);
		end
		fprintf('%s: pu0=%d, ECGPUWave=%d, gathered=%d\n', annotations_to_compare{i},...
				length(target_idx), length(ecgpuwave_peak_locations{i}), label_matches(i, end));
		label_matches(i, :) = label_matches(i, :) ./ length(target_idx);
		plot(label_matches(i, :), plot_str{i}, 'LineWidth', 3);
		legend_str{i} = sprintf('%s, %d peaks', legend_str{i}, length(target_idx));
		if i == 1, hold on; end
	end
	xlabel('ECGPUWave Predictions');
	ylabel('Accuracy');
	title(sprintf('Record = %s', record_no));
	set(gca, 'XTick', 1:length(plus_minus_windows)+1);
	temp = strcat(setstr(177), strread(num2str(plus_minus_windows),'%s'));
	set(gca, 'XTickLabel', {'0', temp{1:end}});
	legend(legend_str, 'Location', 'SouthEast');
	xlim([1, length(plus_minus_windows)+1]);
	grid on;
	file_name = sprintf('/home/anataraj/NIH-craving/ecgpuwave/osea20-gcc/comparison_plots/%s_peaks', record_no);
	savesamesize(gcf, 'file', file_name, 'format', get_project_settings('image_format'));
else
	fprintf('No Peak Labels!\n');
end

