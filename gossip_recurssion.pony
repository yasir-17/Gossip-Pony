use "collections"
use "random"
use "time"
use @exit[None](code: I32)

actor Worker
  let _env: Env
  let id: USize
  let _main: Main
  var _neighbors: Array[Worker tag] = Array[Worker tag]
  var rumor_count: USize = 0
  var is_active: Bool = false

  new create(env: Env, idd: USize, main: Main) =>
    _env = env
    id = idd
    _main = main

  be set_neighbors(neighbors: Array[Worker tag] iso) =>
    _neighbors = consume neighbors

  be start_rumor() =>
    is_active = true
    rumor_count = rumor_count + 1
    propagate_rumor()

  be receive_rumor(sender_id: USize) =>
    rumor_count = rumor_count + 1
    if rumor_count < 10 then
      if not is_active then
        is_active = true
        propagate_rumor()
      end
    else
      is_active = false
      //_env.out.print("Node " + id.string() + " has reached max rumor count")
      // Notify all neighbors to remove this node
      for neighbor in _neighbors.values() do
        _env.out.print("Node " + id.string() + " removed neighbor " + neighbor.id.string())
        neighbor.remove_neighbor(this)  // A.remove_neighbor(B)
      end
      _main.node_finished(id)
    end

  be remove_neighbor(neighbor: Worker tag) =>
    _neighbors = Array[Worker tag].create(_neighbors.size())
    for n in _neighbors.values() do
      if (n isnt neighbor) then
        _neighbors.push(n)
      end
    end
    // _env.out.print("Node " + id.string() + " removed neighbor " + neighbor.id.string())

  be propagate_rumor() =>
    if (_neighbors.size() > 0) and is_active then
      let rand = Rand(Time.nanos().u64())
      let neighbor_index = rand.int(_neighbors.size().u64()).usize()
      try
        _neighbors(neighbor_index)?.receive_rumor(id)
      end
      propagate_rumor()
    elseif rumor_count >= 10 then
      is_active = false
      _main.node_finished(id)
    end

actor Main
  let _env: Env
  let _node_count: USize
  var _start_time: U64
  let _workers: Array[Worker tag]
  var _finished_nodes: Set[USize] = Set[USize]
  var _count:U64 = 0

  new create(env: Env) =>
    _env = env
    let args = env.args

    _node_count = try args(1)?.usize()? else 0 end
    let topology = try args(2)? else "" end

    _workers = Array[Worker tag](_node_count)
    for i in Range(0, _node_count) do
      _workers.push(Worker(env, i, this))
    end

    _start_time = 0
    setup_and_start(topology)

  be setup_and_start(topology: String) =>
    match topology
    | "line" => setup_line_topology()
    | "full" => setup_full_topology()
    end

    // Start the rumor from a random node
    _start_time = Time.nanos()
    restart_rumor()

  be node_finished(id: USize) =>
    _finished_nodes.set(id)
     _env.out.print("finished node size is" + _finished_nodes.size().string())
    if _finished_nodes.size() > ((0.4 * _node_count.f64()).u64().usize()) then
      let end_time = Time.nanos()
      let duration = end_time - _start_time
      _env.out.print("All nodes finished. Total time: " + (duration.f64() / 1e9).string() + " seconds")
      _env.out.print("Total number of nodes finished: " + _finished_nodes.size().string())
      _env.out.print("Total number of rumors: " + _count.string())
    else
      _count = _count + 1
      restart_rumor()
  end

  fun ref restart_rumor() =>
    let unfinished_nodes = Array[USize](_node_count)
    for i in Range(0, _node_count) do
      if not _finished_nodes.contains(i) then
        unfinished_nodes.push(i)
      end
    end

    if unfinished_nodes.size() > 0 then
      let rand = Rand(Time.nanos().u64())
      let random_index = rand.int(unfinished_nodes.size().u64()).usize()
      try
        let node_id = unfinished_nodes(random_index)?
        _workers(node_id)?.start_rumor()
      end
    end

  fun ref setup_line_topology() =>
    for i in Range(0, _workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      if i > 0 then try neighbors.push(_workers(i-1)?) end end
      if i < (_workers.size() - 1) then try neighbors.push(_workers(i+1)?) end end
      try _workers(i)?.set_neighbors(consume neighbors) end
    end

  fun ref setup_full_topology() =>
    for i in Range(0, _workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      for j in Range(0, _workers.size()) do
        if i != j then try neighbors.push(_workers(j)?) end end
      end
      try _workers(i)?.set_neighbors(consume neighbors) end
    end