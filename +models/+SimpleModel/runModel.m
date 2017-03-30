% Creates a simple model

simInst = sim.Instance();

close all;

x = 1:5;
y = 1:5;

[X, Y] = meshgrid(x, y);

trafficGrid = agents.roads.Network(0.25);
simInst.addCallee(trafficGrid);

for i = 1:numel(X)
	location.x = X(i);
	location.y = Y(i);
	trafficGrid.addIntersection(location);
end

for i = 1:(numel(X) - numel(x))
	trafficGrid.addRoad(trafficGrid.intersections{i}, trafficGrid.intersections{i + numel(x)});
end

for i = 1:numel(Y)
	if (mod(i, numel(y)) == 0)
		continue;
	end
	trafficGrid.addRoad(trafficGrid.intersections{i}, trafficGrid.intersections{i + 1})
end

simInst.runSim();

path = trafficGrid.findPath(trafficGrid.intersections{1}, trafficGrid.roads{end - 5}, 0);
disp('Plotting');
fig = trafficGrid.plot();
hold on;
trafficGrid.plotPath(path, fig);


