function[] = format_malai_csv_files()

%{
normal
2013, 11, 04, 16, 24, 52.107
2013, 11, 04, 16, 29, 52.839
shift right
2013, 11, 04, 16, 30, 52.203
2013, 11, 04, 16, 36, 01.165
shift bottom
2013, 11, 04, 16, 36, 33.656
2013, 11, 04, 16, 42, 11.777
%}

matlab_1970 = datenum('1970', 'yyyy');
ecg_data = csvread('/home/anataraj/NIH-craving/ecg_data/Malai_zephyr_drift_test/ecg.csv');
DateString = str2num(datestr((ecg_data(:, 1) / 8.64e7) + matlab_1970, 'yyyy, mm, dd, HH, MM, SS.FFF'));
assert(size(DateString, 1) == size(ecg_data, 1));
mm_dd_etc = strrep(datestr((ecg_data(1, 1) / 8.64e7) + matlab_1970, 'yyyy, mm, dd, HH, MM, SS'), ', ', '_');

if ~exist(fullfile('/home/anataraj/NIH-craving/ecg_data/Malai_zephyr_drift_test', mm_dd_etc))
	mkdir(fullfile('/home/anataraj/NIH-craving/ecg_data/Malai_zephyr_drift_test', mm_dd_etc));
end

filename = fullfile('/home/anataraj/NIH-craving/ecg_data/Malai_zephyr_drift_test', mm_dd_etc, sprintf('%s_ECG.csv', mm_dd_etc));
csvwrite(filename, [DateString, ecg_data(:, end)]);

keyboard

