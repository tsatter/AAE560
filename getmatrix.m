a=length(connectivity_matrix);
NodeInfo=zeros(a,4);
[bounds, node, way, ~] = assign_from_parsed(parsed_osm);
for i=1:1:a
   NodeInfo(i,1)=i;
   NodeInfo(i,4)=node.id(i);
   for j=1:1:2
       g=j+1;
       NodeInfo(i,g)=node.xy(j,i);
   end
end