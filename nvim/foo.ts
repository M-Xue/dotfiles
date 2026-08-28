function fibbonacci(n: number): number {
  if (n <= 1) return n;
  return fibbonacci(n - 1) + fibbonacci(n - 2);
}
const b = {
_selection: [];
    get selection() {
        return this._selection;
    }
    set selection (value) {
        this._selection = value;
    }   
}
function foo (bar) {
    
}       
console.log(fibbonacc i(10));

function greet(name: string): string {
    return `Hello, ${name}!`;
}
console.log(greet("World"));

function multiply(a: number, b: number): number {
    return a * b;
}
console.log(multiply(5, 3));

// Write me a function that multiplies a number by one of its factors

// Graph implementation using adjacency list
class Graph {
    private adjacencyList: Map<number, number[]>;

    constructor() {
        this.adjacencyList = new Map();
    }

    addVertex(vertex: number): void {
        if (!this.adjacencyList.has(vertex)) {
            this.adjacencyList.set(vertex, []);
        }
    }

    addEdge(vertex1: number, vertex2: number): void {
        this.adjacencyList.get(vertex1)?.push(vertex2);
        this.adjacencyList.get(vertex2)?.push(vertex1); // For undirected graph
    }

    // Breadth-First Search implementation
    bfs(startVertex: number): number[] {
        const visited = new Set<number>();
        const queue: number[] = [];
        const result: number[] = [];

        // Add the starting vertex to the queue and mark it as visited
        queue.push(startVertex);
        visited.add(startVertex);

        while (queue.length > 0) {
            // Remove the first vertex from the queue
            const currentVertex = queue.shift()!;
            result.push(currentVertex);

            // Get all adjacent vertices
            const neighbors = this.adjacencyList.get(currentVertex) || [];

            // For each neighbor of the current vertex
            for (const neighbor of neighbors) {
                if (!visited.has(neighbor)) {
                    visited.add(neighbor);
                    queue.push(neighbor);
                }
            }
        }

        return result;
    }
}

// Example usage:
const graph = new Graph();

// Add vertices
[0, 1, 2, 3, 4].forEach(vertex => graph.addVertex(vertex));

// Add edges to create the following graph:
//    0
//   / \\
//  1   2
//  |   |
//  3   4
graph.addEdge(0, 1);
graph.addEdge(0, 2);
graph.addEdge(1, 3);
graph.addEdge(2, 4);

// Perform BFS starting from vertex 0
console.log("BFS starting from vertex 0:", graph.bfs(0));

