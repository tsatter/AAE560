classdef Network < agents.base.SimpleAgent;
	%NETWORK Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		roads = {};
		garages = {};
		intersections = {};
		maxElementLength;
	end
	
	methods
		
		function obj = Network(maxElementLength)
			obj.maxElementLength = maxElementLength;
		end
		
		function addGarage(obj, location)
			garage = agents.roads.Garage(location);
			obj.garages{end + 1} = garage;
		end
		
		function addIntersection(obj, location)
			intersection = agents.roads.Intersection(location);
			obj.instance.addCallee(intersection);
			obj.intersections{end + 1} = intersection;
		end
		
		function addRoad(obj, from, to)
			dx = to.location.x - from.location.x;
			dy = to.location.y - from.location.y;
			distance = norm([dx, dy]);
			numElements = ceil(distance / obj.maxElementLength);
			% Create connectors 
			connectors{1} = from;
			for i = 1:(numElements - 1)
				location.x = from.location.x + (dx * i / numElements);
				location.y = from.location.y + (dy * i / numElements);
				connectors{i + 1} = agents.roads.Connector(location);
			end
			connectors{end + 1} = to;
			
			lastRoad1 = [];
			lastRoad2 = [];
			
			for i = 1:(numel(connectors) - 1)
				connector1 = connectors{i};
				connector2 = connectors{i + 1};
				
				% Connect roads
				road1 = agents.roads.RoadElement(connector1, connector2);
				road2 = agents.roads.RoadElement(connector2, connector1);
				obj.instance.addCallee(road1);
				obj.instance.addCallee(road2);
				
				% Make sure connectors are linked
				
				% Handle intersections
				switch class(connector1)
					case 'agents.roads.Intersection'
						connector1.addConnection(road1);
					case 'agents.roads.Connector'
						if ~isempty(lastRoad1)
							connectors{i}.addConnection(lastRoad1, road1);
							connectors{i}.addConnection(road2, lastRoad2);
						end
				end

				switch class(connector2)
					case 'agents.roads.Intersection'
						connector2.addConnection(road2);
% 					case 'agents.roads.Connector'
% 						if ~isempty(lastRoad2)
% 							connectors{i}.addConnection(road2, lastRoad2);
% 						end
				end
				
				lastRoad1 = road1;
				lastRoad2 = road2;
				
				% Add roads
				obj.roads{end + 1} = road1;
				obj.roads{end + 1} = road2;
			end
			
		end
		
		function pathIdList = findPath(obj, from, to, showPlot)
			if (nargin < 4)
				showPlot = 0;
			end
			% Djikstra algorithm for finding the shortest path between two
			% connectors
			if showPlot
				figure;
				hold on;
				from.plot('b');
				to.plot('r');
				axis equal;
			end
			q = util.PQ2(1);
			path = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
			visitedList = [];
			
			% Reset all costs
			for i = 1:numel(obj.roads)
				obj.roads{i}.cost = inf;
			end
			
			for i = 1:numel(obj.intersections);
				obj.intersections{i}.cost = inf;
			end
			
			currAgent = from; % Starting point
			currAgent.cost = 0;
			while (currAgent.id ~= to.id)
				visitedList(end + 1) = currAgent.id;
				if showPlot
					currAgent.plot();
					drawnow();
				end
				% Push connections to the stack with their cost
				switch class(currAgent)
					case 'agents.roads.RoadElement'
						nextList = currAgent.to.getConnections(currAgent);
					case 'agents.roads.Intersection'
						nextList = currAgent.getConnections();
					case 'agents.roads.Garage'
						nextList = currAgent.getConnections();
				end
				
				for i = 1:numel(nextList)
					next = nextList{i};

					
					% Allow next destinations be either roads or
					% destination
					if isa(next, 'agents.roads.RoadElement') || (next.id == to.id)
						possibleCost = currAgent.cost + next.getLength() / next.speedLimit; % Time to traverse, need to integrate traffic level
						if (possibleCost < next.cost)
							next.cost = possibleCost; % Only set new cost if it is lower
							path(next.id) = currAgent.id;
						end
						
						% Only add if not visited
						if ~any(visitedList == next.id);
							q.push(next, next.cost);
						end
					end
						
				end
				
				% Select the next element and push the current agent to the
				% path stack
				flag = true;
				while flag
					currAgent = q.pop();
					flag = any(visitedList == currAgent.id);
				end
			end
			
			% Return the id list of the path
			pathIdList = to.id;
			pathIdList(end + 1) = path(to.id);
			while (pathIdList(end) ~= from.id)
				pathIdList(end + 1) = path(pathIdList(end));
			end
		end
		
		function plotPath(obj, pathIdList, figHandle)
			figure(figHandle);
			for i = 1:numel(pathIdList)
				agent = obj.instance.getCallee(pathIdList(i));
				handle = agent.plot('r');
				set(handle, 'LineWidth', 3);
			end
		end
		
		function figHandle = plot(obj)
			
			figHandle = figure;
			axis equal;
			hold on;
			for i = 1:numel(obj.roads)
				obj.roads{i}.plot();
			end
		end
		
	end
	
end

