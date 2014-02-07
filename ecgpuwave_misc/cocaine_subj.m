function[] = cocaine_subj(record_no, annotation_file)

% cocaine_subj('P20_040', 'wqrs')

%{
1. make_csv_for_puwave() creates a .csv file which can be fed into ECGPUWave EPS Ltd C version to get annotation file atest. For P20_040d I have already created the csv file
2. Create .dat and .hea file by running wrsamp -F 250 -i P20_040d.csv -o P20_040d 0
3. Update subject Id in zephyr_easytest.c file
4. Complie it as gcc -o zephyr zephyr_easytest.c qrsdet.o bdac.o classify.o rythmchk.o noisechk.o match.o postclas.o analbeat.o qrsfilt.o -lwfdb -lcurl
5. Run it as ./zephyr
6. At the end of step 4 you should be having a atest file which can be used in the code below
7. Run display_mit_peaks for an overlay of CRF vs ECGPU label assignments
%}

% make_csv_for_puwave();

annotations_dir = get_project_settings('annotations');

% MIT BIH or Siemens, etc
record_type = 0;

% Use annotations and get peak labels
matlab_label_assgnmnts = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, annotation_file, record_type);
mit_bih_peaks = struct();
mit_bih_peaks.annt = matlab_label_assgnmnts;
save(fullfile(annotations_dir, sprintf('%s_%s.mat', record_no, annotation_file)), '-struct', 'mit_bih_peaks');

