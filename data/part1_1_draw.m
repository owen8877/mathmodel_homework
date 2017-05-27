data = load('data.mat');
pollution = data.pollution;
station = data.station;

draw_which = 2;

x = station.x;
y = station.y;
z = station.cDensity(:, draw_which);

markTable = ['o'; '+'; 'x'; '*'; 's'];
colorTable = {'yellow'; 'cyan'; 'red'; 'green'; 'blue'};

figure
hold on;

figureWidth = 3e4;
figureHeight = 2e4;

% draw background
[X, Y, Z] = griddata(x, y, z, linspace(0, figureWidth)', linspace(0, figureHeight), 'v4');

contourf(X, Y, Z, 30);
colormap(1-gray);

plots = ones(5);

% draw circles
for i = 1:5
    currentStation = find(station.function==i);
    % scatter(x(currentStation), y(currentStation), z(currentStation) * 5, markTable(i));
    plots(i) = scatter(x(currentStation), y(currentStation), max(z(currentStation) * 3, 0.2), colorTable{i}, 'filled');
end

title(['Pollution of ' pollution.name{draw_which}])
legend('Interpolated data', 'Living', 'Industry', 'Mountain', 'Traffic', 'Park');