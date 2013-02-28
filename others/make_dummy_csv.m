function[] = make_dummy_csv()

subject_id = 'P20_061';
sensor_id = 'Sensor_1';
session_id = '2013_01_18-00_01_01';
start_hh = 13;
start_mm = 51;
start_ss = 20.433;
end_hh = 15;
end_mm = 14;
end_ss = 16.434;
dd = 17;
mm = 01;
yy = 2013;

how_many_millisec = 1000*etime(datevec(sprintf('%d:%d:%0.3f', end_hh, end_mm, end_ss)), datevec(sprintf('%d:%d:%0.3f', start_hh, start_mm, start_ss)));
csv_mat = zeros(how_many_millisec, 7);
size(csv_mat)
csvwrite('/home/anataraj/NIH-craving/data/P20_061/Sensor_1/2013_01_18-00_01_01/2013_01_18-13_52_01_ECG.csv', csv_mat);

how_many_sec = etime(datevec(sprintf('%d:%d:%0.3f', end_hh, end_mm, end_ss)), datevec(sprintf('%d:%d:%0.3f', start_hh, start_mm, start_ss)));
csv_mat = zeros(how_many_sec, 40);
size(csv_mat)
csvwrite('/home/anataraj/NIH-craving/data/P20_061/Sensor_1/2013_01_18-00_01_01/2013_01_18-13_52_01_Summary.csv', csv_mat);

