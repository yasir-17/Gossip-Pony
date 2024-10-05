use "collections"
use "random"
use "time"

actor Main
  new create(env: Env) =>
    try
      let args = env.args
      if args.size() < 3 then
        env.out.print("Usage: " + args(0)? + " <numNodes> <topology>")
        return
      end

      let num_nodes = args(1)?.usize()?
      let topology = args(2)?
      let nodes = Array[Node].init(Node(env, 0), num_nodes)
      
      // Initialize nodes with their IDs
      for i in Range(0, num_nodes) do
        nodes(i)? = Node(env, i)
      end

      let network = match topology
      | "full" => FullNetwork(nodes)
      | "3d" => Grid3D(nodes)
      | "line" => LineTopology(nodes)
      | "imperfect3d" => ImperfectGrid3D(nodes)
      else
        env.out.print("Invalid topology")
        return
      end

      // Start the gossip
      nodes(0)?.start_rumor()
    else
      env.out.print("Error parsing arguments")
    end

actor Node
  let _env: Env
  let _id: USize
  var _heard_count: USize = 0
  let _max_heard: USize = 10
  var _neighbors: Array[Node] = Array[Node]
  let _rand: Random

  new create(env: Env, id: USize) =>
    _env = env
    _id = id
    _rand = Rand

  be add_neighbor(neighbor: Node) =>
    _neighbors.push(neighbor)

  be receive_rumor() =>
    _heard_count = _heard_count + 1
    _env.out.print("Node " + _id.string() + " received rumor " + _heard_count.string())
    if _heard_count < _max_heard then
      try
        let index = _rand.int[USize](_neighbors.size())
        _neighbors(index)?.receive_rumor()
      else
        _env.out.print("Error selecting neighbor")
      end
    else
      _env.out.print("Node " + _id.string() + " received max rumors")
    end

  be start_rumor() =>
    receive_rumor()

class FullNetwork
  let _nodes: Array[Node]

  new create(nodes: Array[Node]) =>
    _nodes = nodes
    for i in Range(0, _nodes.size()) do
      for j in Range(0, _nodes.size()) do
        if i != j then
          try _nodes(i)?.add_neighbor(_nodes(j)?) end
        end
      end
    end

class Grid3D
  let _nodes: Array[Node]

  new create(nodes: Array[Node]) =>
    _nodes = nodes
    // Implementation for 3D grid topology
    // This is a simplified version and doesn't actually create a 3D grid

class LineTopology
  let _nodes: Array[Node]

  new create(nodes: Array[Node]) =>
    _nodes = nodes
    for i in Range(0, _nodes.size()) do
      if i > 0 then
        try _nodes(i)?.add_neighbor(_nodes(i-1)?) end
      end
      if i < (_nodes.size() - 1) then
        try _nodes(i)?.add_neighbor(_nodes(i+1)?) end
      end
    end

class ImperfectGrid3D
  let _nodes: Array[Node]

  new create(nodes: Array[Node]) =>
    _nodes = nodes
    // Implementation for imperfect 3D grid topology
    // This is a simplified version and doesn't actually create an imperfect 3D grid