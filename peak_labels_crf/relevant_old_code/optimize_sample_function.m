function[] = optimize_sample_function()

x_and_y = rand(2, 1);

% options = optimset('Display', 'iter', 'largescale', 'off', 'gradobj', 'on', 'derivativecheck', 'on');
% [x_and_y, fval] = fminunc(@gradient_simple_function, x_and_y, options);
options.Derivativecheck = 'on';
options.TolFun = 1e-6;
x_and_y = minFunc(@gradient_simple_function, x_and_y, options);

x = x_and_y(1);
y = x_and_y(2);
f = -1 + (2 * x) - x^2 - (100 * y^2) + (200 * y * x^2) - (100 * x^4);
fprintf('Maximum f(x, y) = %d at x=%0.4f and y=%0.4f\n', f, x, y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[f, g] = gradient_simple_function(x_and_y)

x = x_and_y(1);
y = x_and_y(2);

f = -(-1 + (2 * x) - x^2 - (100 * y^2) + (200 * y * x^2) - (100 * x^4));

g(1, :) = -(2 - (2 * x) + (400 * x * y) - (400 * x^3));
g(2, :) = -((-200 * y) + (200 * x^2));

