local _, A = ...

-- Pure graph search, kept separate from the game so it can be exercised locally.
function A.Shortest(nodes, edges, from, to, options)
 local dist, previous, closed = {[from]=0}, {}, {}
 options=options or {}
 while true do
  local current, best
  for id,cost in pairs(dist) do
   if not closed[id] and (not best or cost<best) then current,best=id,cost end
  end
  if not current then return nil end
  if current==to then
   local route={}
   while current~=from do
    local leg=previous[current]
    if not leg then return nil end
    table.insert(route,1,leg); current=leg.from
   end
   return route,best
  end
  closed[current]=true
  for _,e in ipairs(edges[current] or {}) do
   local allowed=(not e.faction or e.faction==options.faction)
   if e.kind=='flight' then allowed=allowed and options.flights and e.confirmed end
   if allowed and nodes[e.to] and e.seconds and e.seconds>=0 then
    local value=best+e.seconds
    if not dist[e.to] or value<dist[e.to] then dist[e.to]=value; previous[e.to]=e end
   end
  end
 end
end

function A.Distance(a,b)
 if not a or not b or a.continent~=b.continent then return nil end
 return math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)
end

function A.Edge(graph, from, to, kind, seconds, text, faction, confirmed)
 if not graph.nodes[from] or not graph.nodes[to] then return end
 graph.edges[from]=graph.edges[from] or {}
 table.insert(graph.edges[from],{from=from,to=to,kind=kind,seconds=seconds,
  text=text,faction=faction,confirmed=confirmed})
end
