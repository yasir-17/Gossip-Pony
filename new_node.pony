use "collections"
use "random"
use "time"

actor Worker
  let _env: Env
  let id: USize
  var _neighbors: Array[Worker tag] = Array[Worker tag]
  var _rumor_count: USize = 0
  let _max_rumors: USize = 10
  let _rand: Random
  let _main: Main tag
  let visited_nodes: Array[USize] = Array[USize]

  new create(env: Env, id': USize, main: Main tag) =>
    _env = env
    id = id'
    _rand = Rand(Time.nanos())
    _main = main
    for idx in Range[USize](0, _neighbors.size()) do
      visited_nodes.push(0)
    end


  be set_neighbors(neighbors: Array[Worker tag] iso) =>
    _neighbors = consume neighbors

  be start_rumor() =>
    _rumor_count = 1
    // _env.out.print("Node " + id.string() + " started the rumor")
    propagate_rumor()

  be receive_rumor(idd: USize) =>
    if idd == this.id then
      this.propagate_rumor()
    elseif _rumor_count < _max_rumors then
      _rumor_count = _rumor_count + 1
      // _env.out.print("Node " + id.string() + " received rumor from Node " + idd.string() + " Count:"  + _rumor_count.string() )
      this.propagate_rumor()
    else
      stop_propagation()
    end

  be propagate_rumor() =>
    // if (_rumor_count < _max_rumors) then
    //   try
    //     let neighbor_idx = _rand.int(_neighbors.size().u64()).usize()
    //     let neighbor = _neighbors(neighbor_idx)?
    //     neighbor.receive_rumor(this.id)
    //     this.receive_rumor(this.id)
    //   end
    // else
    //   stop_propagation()
    // end

    // while (_rumor_count < _max_rumors) do
    if (_rumor_count < _max_rumors) then
      _env.out.print("Node " + this.id.string() + "Rumour " + _rumor_count.string())
      try
          _env.out.print(this.id.string())
          let neighbor_idx = _rand.int(_neighbors.size().u64()).usize()
          let neighbor = _neighbors(neighbor_idx)?
          _env.out.print("index"+neighbor_idx.string())
          let current_rumors = visited_nodes(neighbor_idx)?
          _env.out.print("R" + current_rumors.string())
        if (current_rumors < _max_rumors) then
          _env.out.print("Here")
          var rumors_to_store: USize = current_rumors
          rumors_to_store = rumors_to_store + 1
          visited_nodes(neighbor_idx)? = rumors_to_store
          neighbor.receive_rumor(this.id)
          this.receive_rumor(this.id)
          end
      end
    else
      stop_propagation()
    end

  fun ref stop_propagation() =>
    // _env.out.print("Node " + id.string() + "has rumors" + _rumor_count.string() + "Visited "+ visited_nodes.size().string() + "Curr size " + _neighbors.size().string())
    // _env.out.print("Node " + id.string() + " stopped propagating")
    _main.node_finished(id)

// actor GossipBoss:
//   let _env: Env

//   new create(env: Env)

// actor PushSumBoss:
//   let _env: Env

//   new create(env: Env)

actor Main
  let _env: Env
  let _node_count: USize
  let _start_time: U64
  let _finished_nodes: Set[String] = Set[String]

  new create(env: Env) =>
    _env = env
    _start_time = Time.nanos()
    let args = env.args
    // if args.size() < 3 then
    //   env.out.print("Usage: " + try args(0)? else "program" end + " <number_of_nodes> <topology>")
    //   r
    // end

    _node_count = try args(1)?.usize()? else 0 end
    let topology = try args(2)? else "" end

    // if (_node_count == 0) or ((topology != "line") and (topology != "full")) then
      // env.out.print("Invalid arguments. Node count must be > 0 and topology must be 'line' or 'full'")
      // return
    // end

    let workers = Array[Worker tag](_node_count)
    for i in Range(0, _node_count) do
      workers.push(Worker(env, i, this))
    end

    match topology
    | "line" => setup_line_topology(workers)
    | "full" => setup_full_topology(workers)
    end

    // match algorithm
    // | "gossip" => GossipBoss
    // | "pushsum" => PushSumBoss
    // end
    
    // Start the rumor from a random node
    let rand = Rand(Time.nanos())
    try
      workers(rand.int(_node_count.u64()).usize())?.start_rumor()
    end

  be node_finished(node_id: USize val) =>
    if not _finished_nodes.contains(node_id.string()) then 
      _finished_nodes.set(node_id.string())
    end
    _env.out.print(_finished_nodes.size().string())
    if _finished_nodes.size() > 50 then
      let end_time = Time.nanos()
      let duration = end_time - _start_time
      _env.out.print("All nodes finished. Total time: " + (duration.f64() / 1e9).string() + " seconds")
      // _env.exitcode(0)
    end

  fun setup_line_topology(workers: Array[Worker tag]) =>
    for i in Range(0, workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      if i > 0 then try neighbors.push(workers(i-1)?) end end
      if i < (workers.size() - 1) then try neighbors.push(workers(i+1)?) end end
      try workers(i)?.set_neighbors(consume neighbors) end
    end

  fun setup_full_topology(workers: Array[Worker tag]) =>
    for i in Range(0, workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      for j in Range(0, workers.size()) do
        if i != j then try neighbors.push(workers(j)?) end end
      end
      try workers(i)?.set_neighbors(consume neighbors) end
    end

