# Distributed Systems Project: Gossip and Push-Sum Protocols

### Team Members
- **Sivaramakrishnan** - UFID: 15400XXX
- **Yasir** - UFID: 

## Project Overview
This project implements two popular distributed algorithms, **Gossip** and **Push-Sum**, to simulate message propagation and average consensus respectively in various network topologies. The following topologies were used:
- **Line**
- **Full Network**
- **3D Grid**
- **Imperfect 3D Grid (Imp3D)**

## What is Working?
- Both **Gossip** and **Push-Sum** algorithms are fully implemented for the four specified topologies.
- The implementation supports dynamic adjustment of the number of nodes in the network.
- Performance is measured by the time it takes for convergence of messages or sums in different topologies.

## Largest Network Tested
We successfully ran the algorithms for networks as large as 1000 nodes for each topology and algorithm combination. The following table summarizes the maximum network sizes tested:

| Algorithm | Topology | Number of Nodes |
|-----------|----------|-----------------|
| Gossip    | Line     | 1000            |
| Gossip    | Full     | 1000            |
| Gossip    | 3D Grid  | 1000            |
| Gossip    | Imp3D    | 1000            |
| Push-Sum  | Line     | 1000            |
| Push-Sum  | Full     | 1000            |
| Push-Sum  | 3D Grid  | 1000            |
| Push-Sum  | Imp3D    | 1000            |

## How to Run
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repository/project2.git
   ./project2.exe <number_of_nodes> <topology> <algorithm>
   ```
2. **Supported Parameters:**
- **number_of_nodes**: Integer specifying the number of nodes in the network (e.g., 1000).
  
- **topology**: Should be one of `line`, `full`, `3d`, `imp3d`.

- **algorithm**: Should be one of `gossip`, `push-sum`.
