use "collections"
use "random"

primitive Topology
  fun full_network(num_nodes: USize): Array[Node] =>
    let nodes = Array[Node](num_nodes)
    for i in Range(0, num_nodes) do
      nodes.push(Node(i))
    end
    for node in nodes.values() do
      for neighbor in nodes.values() do
        if neighbor != node then
          node.add_neighbor(neighbor)
        end
      end
    end
    nodes

  fun grid_3d(num_nodes: USize): Array[Node] =>
    let nodes = Array[Node](num_nodes)
    for i in Range(0, num_nodes) do
      nodes.push(Node(i))
    end
    let grid_size = (num_nodes.f64().pow(1.0/3.0)).usize()
    for i in Range(0, num_nodes) do
      let x = i / (grid_size * grid_size)
      let y = (i / grid_size) % grid_size
      let z = i % grid_size
      for (dx, dy, dz) in [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)] do
        let nx = x + dx
        let ny = y + dy
        let nz = z + dz
        if (nx >= 0) and (nx < grid_size) and (ny >= 0) and (ny < grid_size) and (nz >= 0) and (nz < grid_size) then
          let j = nx * (grid_size * grid_size) + ny * grid_size + nz
          try
            nodes(i)?.add_neighbor(nodes(j)?)
          end
        end
      end
    end
    nodes

  fun line(num_nodes: USize): Array[Node] =>
    let nodes = Array[Node](num_nodes)
    for i in Range(0, num_nodes) do
      nodes.push(Node(i))
    end
    for i in Range(0, num_nodes) do
      if i > 0 then
        try nodes(i)?.add_neighbor(nodes(i - 1)?) end
      end
      if i < (num_nodes - 1) then
        try nodes(i)?.add_neighbor(nodes(i + 1)?) end
      end
    end
    nodes

  fun imperfect_grid_3d(num_nodes: USize): Array[Node] =>
    let nodes = grid_3d(num_nodes)
    let rand = Random
    for node in nodes.values() do
      try
        let random_neighbor = nodes(rand.int[USize](nodes.size()))?
        if random_neighbor != node then
          node.add_neighbor(random_neighbor)
        end
      end
    end
    nodes

actor Node
  let _env: Env
  let _id: USize
  let _neighbors: Array[Node] = Array[Node]
  var _rumor_count: USize = 0
  let _max_rumor_count: USize = 10

  new create(id: USize, env: Env) =>
    _id = id
    _env = env

  be add_neighbor(neighbor: Node) =>
    _neighbors.push(neighbor)

  be receive_rumor() =>
    _rumor_count = _rumor_count + 1
    if _rumor_count <= _max_rumor_count then
      spread_rumor()
    elseif _rumor_count == _max_rumor_count then
      _env.out.print("Node " + _id.string() + " finished spreading rumor")
    end

  be spread_rumor() =>
    try
      let rand = Random
      if _neighbors.size() > 0 then
        let random_neighbor = _neighbors(rand.int[USize](_neighbors.size()))?
        random_neighbor.receive_rumor("thi")
      end
    end

actor Main
  new create(env: Env) =>
    try
      if env.args.size() < 3 then
        env.out.print("Usage: gossip <num_nodes> <topology>")
        error
      end

      let num_nodes = env.args(1)?.usize()?
      let topology = env.args(2)?
      let rand = Random

      let nodes = match topology
      | "full_network" => Topology.full_network(num_nodes)
      | "grid_3d" => Topology.grid_3d(num_nodes)
      | "line" => Topology.line(num_nodes)
      | "imperfect_grid_3d" => Topology.imperfect_grid_3d(num_nodes)
      else
        env.out.print("Unknown topology: " + topology)
        error
      end

      let start_node = nodes(rand.int[USize](nodes.size()))?
      start_node.receive_rumor()
    else
      env.out.print("Error initializing the network")
    end