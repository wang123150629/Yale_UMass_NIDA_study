function[] = compare_toolboxes(record_no)

%{
addpath('/home/anataraj/NIH-craving/scripts/ecgpuwave_physionet')
which limits.m
ecgpuwave_physionet_res = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, 'atr', 0);
rmpath('/home/anataraj/NIH-craving/scripts/ecgpuwave_physionet')
%}

addpath('/home/anataraj/NIH-craving/scripts/ecgpuwave_malai')
which limits.m
ecgpuwave_malai_res = limits('osea20-gcc', 'osea20-gcc', 'osea20-gcc', record_no, 'atr', 0);

%{
names = fieldnames(ecgpuwave_physionet_res);
for n = 1:length(names)
	assert(isequaln(getfield(ecgpuwave_physionet_res, names{n}), getfield(ecgpuwave_malai_res, names{n})));
end
fprintf('Perfect Matching!\n');
%}

keyboard

