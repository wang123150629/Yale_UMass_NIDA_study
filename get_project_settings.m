function[out] = get_project_settings(request)

switch request
case 'plots', out = fullfile(pwd, 'plots');
case 'data', out = fullfile(pwd, 'data');
case 'results', out = fullfile(pwd, 'results');
case 'image_format', out = sprintf('-dpng');
otherwise, error('Invalid request!');
end
