use "collections"
use "random"
use "time"
use "math"

actor Worker
  /* General Fields */
  let _env: Env
  let id: USize
  let main: Main
  var neighbors: Array[Worker tag] = Array[Worker tag]
  let algorithm : String
  
  /* Gossip Fields */
  var rumor_count: USize = 0

  /*Push Sum Fields */
  var terminate: Bool = false
  var converged : Bool = false
  var s: F64
  var w: F64 = 1
  var delta_count : USize = 0
  var prev_ratio: F64 = 0
  let base:F64 = 10
  let power:F64 = -10.0
  let pushsum_threshold: F64 = base.pow(power)
  
  
  new create(env: Env, id': USize, main': Main, algorithm': String) =>
    _env = env
    id = id'
    main = main'
    s = id'.f64()
    algorithm = algorithm'

  be set_neighbors(neighbors': Array[Worker tag] iso) =>
    neighbors = consume neighbors'

  be start() =>
    rumor_count = rumor_count + 1
    propagate()

  be receive(sum: F64, weight: F64) =>
    if terminate == true then
      return
    end

    if algorithm == "gossip" then
      rumor_count = rumor_count + 1
      if rumor_count < 10 then
        propagate()
      else
        main.node_finished(this.id)
      end
    
    else
      if converged then
        propagate()
      else
        if delta_count < 3 then 
          s = s + sum
          w = w + weight

          let curr_ratio: F64 = s/w
          let delta_ratio: F64 = curr_ratio - prev_ratio
          prev_ratio = curr_ratio

          if delta_ratio.abs() < pushsum_threshold then
            delta_count = delta_count + 1
            if delta_count == 3 then
                converged = true
                main.node_finished(this.id)
            else
                propagate()
            end
          else
            delta_count = 0
            propagate()
          end
        end
      end
    end

  be propagate() =>
    if neighbors.size() > 0 then
        let rand1 = Rand(Time.nanos().u64())
        if algorithm == "pushsum" then
            try
            let neighbor_index = rand1.int(neighbors.size().u64()).usize()
            let sum:F64 = s/2
            let weight:F64 = w/2
            s = sum
            w = weight
            neighbors(neighbor_index)?.receive(s, w)
            end
        end
        if algorithm == "gossip" then
            let rand2 = Rand(Time.nanos().u64())
            let neighbor_index = rand2.int(neighbors.size().u64()).usize()
            try 
                neighbors(neighbor_index)?.receive(s, w)
            end
        end
      end

  be terminated() =>
    terminate = true


actor Main
  let _env: Env
  let _node_count: USize
  var _start_time: U64
  let _workers: Array[Worker tag]
  var converged_nodes: Set[USize] = Set[USize]
  let threshold: F64 = 0.7

  new create(env: Env) =>
    _env = env
    let args = env.args

    _node_count = try args(1)?.usize()? else 0 end
    let topology = try args(2)? else "" end
    let algorithm = try args(3)? else "" end

    _workers = Array[Worker tag](_node_count)
    for i in Range(0, _node_count) do
      _workers.push(Worker(env, i, this, algorithm))
    end

    _start_time = 0
    setup_and_start(topology)

  be setup_and_start(topology: String) =>
    match topology
    | "line" => setup_line_topology()
    | "full" => setup_full_topology()
    | "3d" => setup_3d_grid_topology()
    | "imp3d" => setup_imperfect_3d_grid_topology()
    end

    // Start the rumor from a random node
    _start_time = Time.nanos()
    start()

  be terminate_nodes() =>
    for i in Range[USize](0, _workers.size()) do 
        try _workers(i)?.terminated() end 
    end
  
  fun ref restart() =>
    let unfinished_nodes = Array[USize](_node_count)
    for i in Range(0, _node_count) do
      if not converged_nodes.contains(i) then
        unfinished_nodes.push(i)
      end
    end

    if unfinished_nodes.size() > 0 then
      let rand = Rand(Time.nanos().u64())
      let random_index = rand.int(unfinished_nodes.size().u64()).usize()
      try
        let node_id = unfinished_nodes(random_index)?
        _workers(node_id)?.start()
      end
    end

  be node_finished(id: USize) =>
    converged_nodes.set(id)
    if converged_nodes.size() > ((threshold * _node_count.f64()).u64().usize()) then
        let end_time = Time.nanos()
        let duration = end_time - _start_time
        _env.out.print("All nodes finished. Total time: " + (duration.f64() / 1e9).string() + " seconds")
        terminate_nodes()
    else
      restart()
    end

  fun ref start() =>
    let rand = Rand(Time.nanos().u64())
    let node_id = rand.int(_node_count.u64()).usize()
    try
    _workers(node_id)?.start()
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

  fun ref setup_3d_grid_topology() =>
    let grid_size = _node_count.f64().cbrt().round().usize()
    for i in Range(0, _workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      let x = i % grid_size
      let y = (i / grid_size) % grid_size
      let z = i / (grid_size * grid_size)

      if x > 0 then try neighbors.push(_workers(i - 1)?) end end
      if x < (grid_size - 1) then try neighbors.push(_workers(i + 1)?) end end
      if y > 0 then try neighbors.push(_workers(i - grid_size)?) end end
      if y < (grid_size - 1) then try neighbors.push(_workers(i + grid_size)?) end end
      if z > 0 then try neighbors.push(_workers(i - (grid_size * grid_size))?) end end
      if z < (grid_size - 1) then try neighbors.push(_workers(i + (grid_size * grid_size))?) end end

      try _workers(i)?.set_neighbors(consume neighbors) end
    end

  fun ref setup_imperfect_3d_grid_topology() =>
    let grid_size = _node_count.f64().cbrt().round().usize()
    let rand = Rand(Time.nanos().u64())

    for i in Range(0, _workers.size()) do
      let neighbors = recover iso Array[Worker tag] end
      let x = i % grid_size
      let y = (i / grid_size) % grid_size
      let z = i / (grid_size * grid_size)

      if x > 0 then try neighbors.push(_workers(i - 1)?) end end
      if x < (grid_size - 1) then try neighbors.push(_workers(i + 1)?) end end
      if y > 0 then try neighbors.push(_workers(i - grid_size)?) end end
      if y < (grid_size - 1) then try neighbors.push(_workers(i + grid_size)?) end end
      if z > 0 then try neighbors.push(_workers(i - (grid_size * grid_size))?) end end
      if z < (grid_size - 1) then try neighbors.push(_workers(i + (grid_size * grid_size))?) end end

      // Add a random neighbor from the list of all actors
      let random_neighbor = rand.int(_workers.size().u64()).usize()
      if random_neighbor != i then try neighbors.push(_workers(random_neighbor)?) end end

      try _workers(i)?.set_neighbors(consume neighbors) end
    end