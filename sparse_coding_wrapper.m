function[] = sparse_coding_wrapper()

lambda = [1e-4, 1e-3, 0.01, 0.015, 0.05, 0.1, 0.15, 0.25];
mul_acc = zeros(1, length(lambda));
crf_acc = zeros(1, length(lambda));
mean_dict = zeros(1, length(lambda));

for l = 1:length(lambda)
	[mul_accuracy, crf_accuracy, mean_dict_elements] = sparse_coding(true, true, false, false, true, lambda(l));
	mul_acc(1, l) = sum(mul_accuracy(:));
	crf_acc(1, l) = sum(crf_accuracy(:));
	mean_dict(1, l) = mean(diag(mean_dict_elements));
end

sparse_coding_plots(11, mul_acc, crf_acc, mean_dict, lambda);

