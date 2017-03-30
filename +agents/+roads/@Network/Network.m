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
				if (i < (numel(connectors) - 1))
					if ~isempty(lastRoad1)
						connector1.addConnection(lastRoad1, road1);
					end
					if ~isempty(lastRoad2)
						connector2.addConnection(road2, lastRoad2);
					end
				end
				lastRoad1 = road1;
				lastRoad2 = road2;
				% Let the connectors know that the roads are connected
				obj.roads{end + 1} = road1;
				obj.roads{end + 1} = road2;
			end
			
		end
		
		function plot(obj)
			
			plotSpacing = 0.01;
			figure;
			hold on;
			for i = 1:numel(obj.roads)
				from = obj.roads{i}.from.location;
				to = obj.roads{i}.to.location;
				angle = atan2(to.y - from.y, to.x - from.x);
				from.x = from.x + sin(angle) * plotSpacing;
				from.y = from.y + cos(angle) * plotSpacing;
				to.x = to.x + sin(angle) * plotSpacing;
				to.y = to.y + cos(angle) * plotSpacing;
				quiver(from.x, from.y, to.x - from.x, to.y - from.y, 0, 'k', 'MaxHeadSize', 0.4);
			end
		end
		
	end
	
end

