use "collections"
use "random"
use "time"

trait Algorithm
  fun ref propagate(env: Env, sender: Node, receiver: Node)
  fun ref update_state(incoming_state: State, node: Node): State
  fun ref terminate(node: Node): Bool

class Gossip is Algorithm
  let _max_rumors: U64 = 10

  fun ref propagate(env: Env, sender: Node, receiver: Node) =>
    receiver.receive_rumor(env, sender._state, this)

  fun ref update_state(incoming_state: State, node: Node): State =>
    node._state

  fun ref terminate(node: Node): Bool =>
    node._curr_rumors >= _max_rumors

class PushSum is Algorithm
  fun ref propagate(env: Env, sender: Node, receiver: Node) =>
    let new_s = sender._state._s / 2
    let new_w = sender._state._w / 2
    sender._state._s = sender._state._s / 2
    sender._state._w = sender._state._w / 2
    let incoming_state = State(new_s, new_w)
    receiver.receive_rumor(env, incoming_state, this)

  fun ref update_state(incoming_state: State, node: Node): State =>
    let new_s = incoming_state._s + node._state._s
    let new_w = incoming_state._w + node._state._w
    let updated_state = State(new_s, new_w)
    let moving_ratio = new_s.f64() / new_w.f64()
    node.add_moving_ratio(moving_ratio)
    updated_state

  fun ref terminate(node: Node): Bool => 
    if node.moving_avg.size() >= 3 then
      let last_three = node.moving_avg.slice(-3)
      last_three.uniq().size() == 1
    else
      false
    end

class State
  var _s: F64
  var _w: F64

  new create(s: F64, w: F64 = 1.0) =>
    _s = s
    _w = w

actor Node
  let _env: Env
  let _id: U64 
  var _curr_rumors: U64 = 0
  var _neighbors: Array[Node] = Array[Node]
  var _state: State
  var moving_avg: Array[F64] = Array[F64]
  let _rand: Random

  new create(env: Env, id: U64) =>
    _env = env
    _id = id
    _rand = Random
    _state = State(id.f64())

  be receive_rumor(env: Env, incoming_state: State, algorithm: Algorithm) =>
    _curr_rumors = _curr_rumors + 1

    if not algorithm.terminate(this) then
      _state = algorithm.update_state(incoming_state, this)
      let neighbor =_neighbors(_rand.int(_neighbors.size().u64()).usize())?
      algorithm.propagate(env, this, neighbor)
    end

  be send_rumor(env: Env, algorithm: Algorithm) =>
    let neighbor = _neighbors(_rand.int(_neighbors.size().u64()).usize())
    algorithm.propagate(env, this, neighbor)

  be add_moving_ratio(ratio: F64) =>
    moving_avg.push(ratio)
    if moving_avg.size() > 3 then
      try
        moving_avg.shift()?
      end
    end

  be add_neighbor(node: Node) =>
    _neighbors.push(node)