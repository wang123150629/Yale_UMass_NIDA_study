function play_with_svm()

load fisheriris
xdata = meas(51:end,3:4);
group = species(51:end);
svmStruct = svmtrain(xdata,group,'autoscale',false);

plot(xdata(:, 1), xdata(:, 2), 'bo'); hold on;

pos = svmStruct.Alpha > 0;
pos_vectors = svmStruct.SupportVectors(pos, :);
[pos_val, pos_idx] = sort(svmStruct.Alpha(pos));
for p = 1:length(pos_idx)
	plot(pos_vectors(pos_idx(p), 1), pos_vectors(pos_idx(p), 2), 'b*');
	disp(sprintf('%0.4f', pos_val(p)));
	keyboard
end

neg = ~pos;
neg_vectors = svmStruct.SupportVectors(neg, :);
[neg_val, neg_idx] = sort(svmStruct.Alpha(neg), 'descend');
for n = 1:length(neg_idx)
	plot(neg_vectors(neg_idx(n), 1), neg_vectors(neg_idx(n), 2), 'r*');
	disp(sprintf('%0.4f', neg_val(n)));
	keyboard
end

keyboard

