classdef Instance < handle
	%INSTANCE Handles all agents in the simulation
	
	properties
		calleeMap; % List of agents
		calleeIndex = 0; % Current index of agents (equal to number of agents added to sim)
		callStack; % Minimum priority queue of next agents to call
		
		currentTime;
	end
	
	methods
		
		function obj = Instance()
			obj.calleeMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
			obj.callStack = util.PQ2(1);
		end
		
		% Add an agent to the sim
		function addCallee(obj, agent)
			obj.calleeIndex = obj.calleeIndex + 1;
			agent.setId(obj.calleeIndex);
			agent.instance = obj;
			obj.calleeMap(obj.calleeIndex) = agent;
			agent.init(); % Initialize
		end
		
		function callee = getCallee(obj, id)
			if obj.calleeMap.isKey(id)
				callee = obj.calleeMap(id);
			else
				callee = {};
			end
		end
		
		function runSim(obj, endTime)
			% Simulate agents from start to end time
			obj.currentTime = 0;
			while (obj.callStack.nElements > 0) && (obj.currentTime <= endTime)
				% Get next agent and run
				[agentIdx, time] = obj.callStack.pop();
				obj.currentTime = time;
				agent = obj.calleeMap(agentIdx);
				agent.runAtTime(obj.currentTime);
			end
		end
		
		function scheduleAtTime(obj, agent, time)
			assert(time >= obj.currentTime);
			obj.callStack.push(agent.id, time);
		end
		

	
		
	end
	
end

