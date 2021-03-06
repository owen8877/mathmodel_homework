data = load('data.mat');
pollution = data.pollution;
station = data.station;

width = 3e4;
height = 2e4;
resolution = 1e2;
x = station.x;
y = station.y;

mapData = load('mapData.mat');

[lonMesh, latMesh] = meshgrid(0:resolution:width, 0:resolution:height); 
blockedData = zeros(width / resolution + 1, height / resolution + 1, pollution.count);

for i = 1:pollution.count
    S = scatteredInterpolant(x, y, station.density(:, i), 'natural');
    Z = S(lonMesh, latMesh);
    Z(~mapData.innerArea) = NaN;
    blockedData(:, :, i) = Z';
end

% for height data
S = scatteredInterpolant(x, y, station.height, 'natural');
Z = S(lonMesh, latMesh);
Z(~mapData.innerArea) = NaN;
heightData = Z';

heightd2Matrix = heightData * NaN;
for i = 2:size(heightData, 1)-1
    for j = 2:size(heightData, 2)-1
        if isnan(heightData(i, j))
            continue
        end

        dx2 = heightData(i+1, j) + heightData(i-1, j) - 2*heightData(i, j);
        dy2 = heightData(i, j+1) + heightData(i, j-1) - 2*heightData(i, j);
        heightd2Matrix(i, j) = dx2 + dy2;
    end    
end
heightd2Matrix = fillmissing(heightd2Matrix, 'constant', 0, 1);
heightd2Matrix = fillmissing(heightd2Matrix, 'constant', 0, 2);

peakCoordinates = cell(pollution.count, 1);

workingFactorIndex = 2;
needFigure = true;

% to generate data, unblock the below
for workingFactorIndex = 1:pollution.count
    working = blockedData(:, :, workingFactorIndex);
    derivative1Matrix = working * NaN;
    derivative2Matrix = working * NaN;
    coordinates = [];
    for i = 2:size(working, 1)-1
        for j = 2:size(working, 2)-1
            if isnan(working(i, j))
                continue
            end

            dx1 = working(i, j) - working(i-1, j);
            dy1 = working(i, j) - working(i, j-1);
            dx2 = working(i+1, j) + working(i-1, j) - 2*working(i, j);
            dy2 = working(i, j+1) + working(i, j-1) - 2*working(i, j);
            derivative1Matrix(i, j) = dx1 + dy1;
            derivative2Matrix(i, j) = dx2 + dy2;

            % if this point is the largest, mark it
            largest = true;
            searchSize = 3;
            for k = -min(searchSize, i-1):min(searchSize, size(working, 1) - i)
                for l = -min(searchSize, j-1):min(searchSize, size(working, 2) - j)
                    if k == 0 && l == 0
                        continue
                    elseif working(i+k, j+l) > working(i, j) || isnan(working(i+k, j+l))
                        largest = false;
                        break
                    end
                end
            end
            if largest
                coordinates = [coordinates; [i, j]];
            end
        end    
    end
    
    pollutionRate = zeros(size(coordinates, 1), 1);
    for i = 1:size(coordinates, 1)
        % pollutionRate(i) = - working(coordinates(i, 1), coordinates(i, 2)) ^ 2 / derivative2Matrix(coordinates(i, 1), coordinates(i, 2));
        pollutionRate(i) = working(coordinates(i, 1), coordinates(i, 2)) ^ 2;
    end
    [sortedPollutionRate, index] = sort(pollutionRate, 'descend');
    latentVector = cumsum(sortedPollutionRate) / sum(sortedPollutionRate);
    cutoff = 0.50;
    primaryStationNumber = find(latentVector > cutoff, 1);
    peakCoordinates{workingFactorIndex} = coordinates(index(1:primaryStationNumber), :);
    
    if ~needFigure
        continue
    end
    
    figure
    title(['Peak points of metal ' int2str(workingFactorIndex)])
    hold on;
    contourf(lonMesh, latMesh, working', 10);
    colorbar;
    scatter(coordinates(:, 1) * resolution, coordinates(:, 2) * resolution);
    hold off;

    realPeak = coordinates(index(1:primaryStationNumber), :);
    maxPeak = coordinates(index(1), :);
    hold on;
    scatter(realPeak(:, 1) * resolution, realPeak(:, 2) * resolution, 'filled', 'y');
    scatter(maxPeak(1, 1) * resolution, maxPeak(1, 2) * resolution, 'filled', 'r');
%     for i = 1:length(coordinates)
%        text(coordinates(i, 1) * resolution, coordinates(i, 2) * resolution, num2str(pollutionRate(i)));
%     end
    hold off;
end

% output: 3_1_p_output.mat
% blockedData, heightData, heightd2Matrix, peakCoordinates