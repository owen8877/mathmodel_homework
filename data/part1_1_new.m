data = load('data.mat');
pollution = data.pollution;
station = data.station;

draw_which = 1;

displayData = station.cDensity(:, draw_which);
% figure
mapDisplay(displayData, ['Pollution of ' pollution.name{draw_which}]);