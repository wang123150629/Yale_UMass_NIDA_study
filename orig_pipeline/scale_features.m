function [feature_extracted_data] = scale_features(feature_extracted_data, cols_to_scale)

other_cols = setdiff([1:size(feature_extracted_data, 2)], cols_to_scale);
abs_min_val = min(min(feature_extracted_data(:, other_cols)));
abs_max_val = max(max(feature_extracted_data(:, other_cols)));

for c = 1:length(cols_to_scale)
	feature_extracted_data(:, cols_to_scale(c)) = scale_data(feature_extracted_data(:, cols_to_scale(c)), abs_min_val, abs_max_val);
end
assert(round_to(min(feature_extracted_data(:)), 10) >= round_to(abs_min_val, 10));
assert(round_to(max(feature_extracted_data(:)), 10) <= round_to(abs_max_val, 10));

