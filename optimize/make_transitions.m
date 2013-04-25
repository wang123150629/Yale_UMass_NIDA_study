function[trans_comb_indicator] = make_transitions(label_comb_indicator)

% Converts [1, 2, 3, 1] to
% [1, 2
%  2, 3
%  3, 1]
nPositions = length(label_comb_indicator);
trans_comb_indicator = [label_comb_indicator(1:nPositions-1)', label_comb_indicator(2:nPositions)'];

