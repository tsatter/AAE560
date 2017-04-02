classdef Network < agents.base.SimpleAgent;
	%NETWORK Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		roads = {};
		garages = {};
		intersections = {};
		connectors = {};
		maxElementLength;
	end
	
	methods
		
		function obj = Network(maxElementLength)
			obj.maxElementLength = maxElementLength;
		end
		
		function addGarage(obj, location, numSpaces)
			
			% Get the nearest connector
			connector = obj.findClosestConnector(location);
			
			% Create the garage
			garage = agents.roads.Garage(location, connector, numSpaces);
			obj.garages{end + 1} = garage;
			obj.instance.addCallee(garage);
			garage.connect();
		end
		
		function addIntersection(obj, location)
			intersection = agents.roads.Intersection(location);
			obj.instance.addCallee(intersection);
			obj.intersections{end + 1} = intersection;
		end
		
		function addRoad(obj, from, to, speedLimit)
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
				obj.connectors{end + 1} = connectors{end};
			end
			connectors{end + 1} = to;
			
			lastRoad1 = [];
			lastRoad2 = [];
			
			for i = 1:(numel(connectors) - 1)
				connector1 = connectors{i};
				connector2 = connectors{i + 1};
				
				% Connect roads
				road1 = agents.roads.RoadElement(connector1, connector2, speedLimit);
				road2 = agents.roads.RoadElement(connector2, connector1, speedLimit);
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
		
		function [pathIdList, cost] = findPath(obj, from, to, showPlot)
			if (nargin < 4)
				showPlot = 0;
			end
			% Djikstra algorithm for finding the shortest path between two
			% connectors
			if showPlot
				figure;
				hold on;
				from.plot('g');
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
				if showPlot && (from.id ~= currAgent.id)
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
						nextList = currAgent.connector.getConnections(currAgent);
				end
				
				for i = 1:numel(nextList)
					next = nextList{i};

					
					% Allow next destinations be either roads or
					% destination
					switch class(next)
						case 'agents.roads.RoadElement'
							costMod = 0;
							if isa(currAgent, 'agents.roads.RoadElement')
								dx = currAgent.to.location.x - currAgent.from.location.x;
								dy = currAgent.to.location.y - currAgent.from.location.y;
								currVect = [dx, dy];
								
								dx = next.to.location.x - next.from.location.x;
								dy = next.to.location.y - next.from.location.y;
								nextVect = [dx, dy];
								if all(currVect == -nextVect)
									costMod = 1;
								end
							end
							
							possibleCost = currAgent.cost + (next.getLength() / next.speedLimit) + costMod; % Time to traverse, need to integrate traffic level
							if (possibleCost < next.cost)
								next.cost = possibleCost; % Only set new cost if it is lower
								path(next.id) = currAgent.id;
							end
							
							% Only add if not visited
							if ~any(visitedList == next.id);
								q.push(next, next.cost);
							end
						otherwise
							path(next.id) = currAgent.id;
							next.cost = currAgent.cost;
							if ~any(visitedList == next.id);
								q.push(next, next.cost);
							end
					end
					
				end
				cost = currAgent.cost;
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
			pathIdList = flip(pathIdList);
		end
		
		function plotPath(obj, pathIdList, figHandle)
			figure(figHandle);
			for i = 1:numel(pathIdList)
				agent = obj.instance.getCallee(pathIdList(i));
				handle = agent.plot('r');
				set(handle, 'LineWidth', 2);
			end
		end
		
		function connector = findClosestConnector(obj, location)
			minDist = inf;
			connector = [];
			
			for i = 1:numel(obj.connectors)
				dx = obj.connectors{i}.location.x - location.x;
				dy = obj.connectors{i}.location.y - location.y;
				dist = norm([dx, dy]);
				if (dist < minDist)
					connector = obj.connectors{i};
					minDist = dist;
				end
			end
		end
		
		function figHandle = plot(obj)
			
			figHandle = figure;
			axis equal;
			hold on;
			for i = 1:numel(obj.roads)
				obj.roads{i}.plot();
			end
			
			for i = 1:numel(obj.intersections)
				handle = obj.intersections{i}.plot('b');
				set(handle, 'MarkerSize', 5);
			end
			
			for i = 1:numel(obj.garages)
				obj.garages{i}.plot('b');
			end
		end
		
	end
	
end

