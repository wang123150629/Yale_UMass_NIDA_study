function[] = tmp_file_to_build_mats(mat_name)

raw_ecg_data = struct();
train = [];
test = [];
for i = 1:3
	for j = 1:3
		load(sprintf('ecg_train_%d%d.mat', i, j));
		train = [train; tmp];
		clear tmp;
		load(sprintf('ecg_test_%d%d.mat', i, j));
		test = [test; tmp];
	end
end

raw_ecg_data.train = train;
raw_ecg_data.test = test;
save(sprintf('/home/anataraj/Desktop/%s.mat', mat_name), '-struct', 'raw_ecg_data');
!rm *.mat;

