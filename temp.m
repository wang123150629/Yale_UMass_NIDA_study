function[] = temp()

x = rand(1, 1);

keyboard

options = optimset('Display', 'iter', 'largescale', 'off', 'gradobj', 'on', 'derivativecheck', 'on');
[x, fval] = minFunc(@gradient_simple_function, x, options);

f = x^2-x-2;
fprintf('Maximum f(x, y) = %d at x=%0.4f\n', f, x);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[f, g] = gradient_log_function(x)

f = log(x^2-x-2);

if nargout > 1
	g(1) = 2*x-1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[f, g] = gradient_simple_function(x)

f = x^2-x-2;

if nargout > 1
	g(1) = 2*x-1;
end

