function[index_maps] = find_start_end_time(subject_profile, summary_mat, behav_mat, resolution)

summ_mat_columns = subject_profile.columns.summ;
behav_mat_columns = subject_profile.columns.behav;

% If the data from summary matrix came first then the first entry in the summary mat is the earliest_start_time else the first entry in the behavior mat is the earliest_start_time. Example 8:38:00
if summary_mat(1, summ_mat_columns.actual_hh) <= behav_mat(1, behav_mat_columns.actual_hh) &...
		  summary_mat(1, summ_mat_columns.actual_mm) <= behav_mat(1, behav_mat_columns.actual_mm)
	earliest_start_time = [summary_mat(1, summ_mat_columns.actual_hh),...
			       summary_mat(1, summ_mat_columns.actual_mm), summary_mat(1, summ_mat_columns.actual_ss)];
else
	earliest_start_time = [behav_mat(1, behav_mat_columns.actual_hh), behav_mat(1, behav_mat_columns.actual_mm), 0];
end

% If the data from summary matrix ended first then the last entry in the behavior mat is the latest_end_time else the last entry in the summary mat is the latest_end_time. Example 17:16:51
if summary_mat(end, summ_mat_columns.actual_hh) <= behav_mat(end, behav_mat_columns.actual_hh) &...
		    summary_mat(end, summ_mat_columns.actual_mm) <= behav_mat(end, behav_mat_columns.actual_mm)
	latest_end_time = [behav_mat(end, behav_mat_columns.actual_hh), behav_mat(end, behav_mat_columns.actual_mm), 59];
else
	latest_end_time = round_to([summary_mat(end, summ_mat_columns.actual_hh),...
			  summary_mat(end, summ_mat_columns.actual_mm), summary_mat(end, summ_mat_columns.actual_ss)], 0);
end

% This step rounds of the time. Example 8:38:00 to 8:00:00
if earliest_start_time(2) >= 0 & earliest_start_time(3) >= 0
	earliest_start_time(2) = 0;
	earliest_start_time(3) = 0;
end

% This step rounds of the time. Example 17:16:51 to 17:59:59
if latest_end_time(2) <= 59 & latest_end_time(3) <= 59
	latest_end_time(2) = 59;
	latest_end_time(3) = 59;
end

% The point being I have n absolute time going from the minimum to the maximum time. Events (summary, raw, behavior, vas data) come and go along this absolute time axis in different resolutions. The index_maps struct has the respective indices for each of those events. To plot an event simply use these indices as the x-axis. The x-axis is limited by the absolute time axis so all these events are well contained within its limits

index_maps = struct();

% Absolute time axis. For example 1:1:35999 seconds = For 9:59:59 it is 35999 seconds
index_maps.time_axis = 1:how_many_seconds_have_elapsed(earliest_start_time, latest_end_time);

% This tells you how far along is the summary data in the absolute time axis. For example 8155 seconds from 8:0:0 and ends at 33411 seconds from the 8:0:0. This data is in 1 second resolution
index_maps.summary = [how_many_seconds_have_elapsed(earliest_start_time,...
		      summary_mat(1, summ_mat_columns.actual_hh:summ_mat_columns.actual_ss)):...
	  	      how_many_seconds_have_elapsed(earliest_start_time,...
		      summary_mat(end, summ_mat_columns.actual_hh:summ_mat_columns.actual_ss))];

% This tells you how far along is the behavior data in the absolute time axis. For example 2280 seconds from 8:0:0 and ends at 32819 seconds from the 8:0:0. This data is in 1 minute (60 seconds) resolution
index_maps.behav = [how_many_seconds_have_elapsed(earliest_start_time,...
		   [behav_mat(1, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm), 0]):60:...
		   how_many_seconds_have_elapsed(earliest_start_time,...
		   [behav_mat(end, behav_mat_columns.actual_hh:behav_mat_columns.actual_mm), 59])];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[total_elapsed_seconds] = how_many_seconds_have_elapsed(time1_vect, time2_vect)

% Converts the time into string representations as the str rep is easy to handle
time1 = sprintf('%d:%d:%d', time1_vect(1), time1_vect(2), round_to(time1_vect(3), 0));
time2 = sprintf('%d:%d:%d', time2_vect(1), time2_vect(2), round_to(time2_vect(3), 0));

% Takes the difference between time1 and time2. Here the total elapsed time between 8:00:00 and 17:59:59 is 9:59:59
temp = datestr(datenum(time2) - datenum(time1), 13);

% Computes the total elapsed seconds. For 9:59:59 it is 35999 seconds
total_elapsed_seconds = str2num(temp(1:2)) * 60^2 + str2num(temp(4:5)) * 60 + str2num(temp(7:8));

