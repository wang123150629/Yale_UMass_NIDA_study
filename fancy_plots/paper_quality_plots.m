function[] = temp()

plot(1:10, rand(1, 10));
set(gcf, 'PaperPosition', [0 0 8 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [8 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, 'test', 'pdf') %Save figure
