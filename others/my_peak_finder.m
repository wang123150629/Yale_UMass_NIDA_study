function[] = my_peak_finder()

close all;

nSamples = 100;
x = 1:nSamples;
noisy_wave = sin(x)+rand(1, nSamples);
plot(x, noisy_wave, 'b-'); hold on;

% this detector moves from left to right while keeping track of the max value and its associted index when it comes across a value even greater then what it is holding, it updates itself. If it comes across a value which is delta less than what it is holding then it write out the max values andrepeats the procedure for the minimum value
delta = 0.5;
[maxtab, mintab] = peakdet(noisy_wave, delta);
plot(maxtab(:, 1), maxtab(:, 2), 'ro');
plot(mintab(:, 1), mintab(:, 2), 'go');





keyboard

