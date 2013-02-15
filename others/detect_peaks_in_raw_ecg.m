function[] = detect_peaks_in_raw_ecg()

raw_ecg_mat_time_res = 250;
subject_threshold = 0.05;
ecg_mat = csvread(sprintf('/home/anataraj/NIH-craving/data/P20_040/Sensor_1/2012_06_27-09_21_36/2012_06_27-09_21_36_ECG_clean.csv'), 1, 0);
x = ecg_mat .* 0.001220703125;
[rr, rs] = rrextract(x, raw_ecg_mat_time_res, subject_threshold);

