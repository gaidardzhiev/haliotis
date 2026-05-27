# Haliotis

The GPU was designed for one kind of problem. A large computation decomposed into thousands of identical subcomputations, each independent, each running the same instruction at the same moment on different data. Graphics. Matrix multiplication. Neural network inference. The architecture is optimized for this so completely that everything else feels like a misuse.

It takes sequential C programs, programs written for a single CPU, with malloc and printf and recursive function calls and linked list traversal, and runs thousands of them simultaneously on GPU hardware, each one isolated from the others, each one believing it owns the machine, while the GPU's own scheduler fills every idle cycle with useful work from a different program that would otherwise be stalling on a memory access.

The result is not a faster sequential program. A single sequential C program will not run faster on a GPU than on a CPU. The result is something different: maximum hardware occupancy from programs that were never written to produce it, falling out naturally from the structure of the machine when you give it enough independent things to do.


## The Problem With GPU Programming Today

Writing for a GPU means thinking like a GPU. You decompose your problem manually into threads. You manage shared memory explicitly. You insert synchronization barriers at the right points. You choose your block size to maximize occupancy. The programmer does the work that the hardware cannot do for itself.

This is the right model for the problems the GPU was designed for. It is the wrong model for the vast majority of programs that exist, which were written for a CPU, by programmers who were thinking about their problem rather than about warps and memory hierarchies.

Haliotis inverts the relationship. The programmer writes a normal C program. The runtime decides how to map it onto the hardware. The GPU's warp scheduler, which already switches between threads with zero overhead whenever one stalls, is exploited at the program level rather than the instruction level. The programmer sees an isolated execution environment. The hardware sees occupancy.


## The Architecture

An RTX 3060 Ti has 38 streaming multiprocessors. Each one can hold up to 1536 threads in flight simultaneously, each with its own live register file. The hardware switches between warps not by saving and restoring registers but because all the register sets exist at the same time and the scheduler simply picks which one runs next. This is how the GPU hides memory latency. When one warp stalls waiting for a memory access that takes hundreds of cycles, another warp runs. If there are enough live warps, the stalls disappear into the background and the execution units stay busy.

A sequential C program stalls on memory constantly. Pointer chasing through data structures, function call overhead, dynamic allocation, environment lookup through scope chains: every one of these touches memory and every memory touch is a potential stall. One program running in one thread wastes most of those cycles. Thousands of independent programs running simultaneously, each stalling at different moments on different memory accesses, give the warp scheduler exactly what it needs to keep the machine at full occupancy.

Haliotis provides each program with what it needs to believe it is running alone. Its own memory space, drawn from a per-context arena allocator. Its own file descriptors, backed by a virtual filesystem populated before launch. Its own standard input, standard output, and standard error. Its own program counter and call stack. The runtime manages these execution contexts the way an operating system manages processes, except the scheduler is running in devicec code and the context switches happen inside the kernel rather than between kernel calls.

There are two levels of scheduling working simultaneously. The inner scheduler, the one Haliotis implements, handles program level context switches between execution namespaces when a context reaches a natural yield point. The outer scheduler, the one the hardware provides, handles instruction level switches between warps continuously and automatically. Both are hiding latency. Both are filling idle cycles. The programmer is responsible for neither.


## The Emulation Layer

A C program expects an operating system. It expects malloc to return memory, printf to produce output, fopen to open files, exit to terminate cleanly. None of these exist in a CUDA kernel. Haliotis provides them.

At the bottom is a syscall emulation table. Twelve operations that cover everything a well behaved C program actually asks the operating system to do. Memory allocation and deallocation. Reading and writing file descriptors. Opening and closing files. Exiting with a status code. Getting the time. On top of that is a device side implementation of the C standard library, enough of itto satisfy programs that use it without modification. The program links against Haliotis instead of libc and the rest is transparent.

The virtual filesystem is populated by the host before the kernel launches. Files the program needs are read on the CPU, copied to device memory, and registered by path. When the program calls fopen, it gets a file descriptor into that virtual table. When it calls fread, it reads from device memory. When it writes to standard output, the bytes go into its per-context output buffer. After the kernel finishes, the host collects every context's output in order and routes it to the right destination.

The emulation is not perfect and does not claim to be. Programs that fork, that handle signals, that spawn threads, that wait for network connections, that require the operating system to grow their heap without bound, these do not run under Haliotis. The boundary is architectural. The GPU thread model does not compose with the Unix process model in those cases. What does run is a large and practically important class: interpreters, parsers, compilers, simulations, graph algorithms, recursive computations, anything that can be described as a function from input to output with bounded memory.


## What Haliotis Is

It is a GPU process namespace manager. Each namespace is an isolated execution context with its own virtual machine state. The manager is the runtime that maps namespaces onto warps, allocates their memory, provides their filesystem and IO, schedules between them at yield points, and collects their output when they finish.

It is also an operating system in miniature. It runs in device code. It schedules independent sequential programs onto hardware that was built for a completely different programming model. It makes that hardware run at full occupancy not by restructuring the programs but by exploiting the fact that independent sequential programs stall on memory at different times, which is precisely what the GPU's latency hiding mechanism was built to absorb.

The programs do not know any of this. They run. They produce output. The output is correct because the emulation layer is correct and the isolation between contexts is structural rather than enforced. Each context has its own memory. There is no shared mutable state between them unless you explicitly arrange for it. A crash in one context does not affect the others. They finish and their output is collected. This is a stronger isolation guarantee than running the same program in parallel processes on a CPU, where the processes share a kernel and a filesystem and potentially a cache. Under Haliotis the isolation is a consequence of the hardware, not a policy imposed on top of it.


## What This Is For

The obvious application is throughput. One program, ten thousand inputs, the time it takes to run it once. Fuzzing, testing, simulation, parameter sweeps, any workload that requires running the same computation many times with different starting conditions.

The less obvious application is isolation. A program that might crash, that might consume unexpected memory, that might loop on certain inputs, can be run safely under Haliotis at scale. The boundary between contexts is hard. The worst a misbehaving context can do is waste its own arena and produce an error in its own output buffer.

The most interesting application is the one that is hardest to state cleanly. It is the demonstration that the boundary between what runs on a CPU and what runs on a GPU is not fixed by the nature of computation. It is fixed by the assumptions that execution environments make about the hardware beneath them. Haliotis changes those assumptions and the boundary moves.


## License

Copyright (C) 2026 Ivan Gaydardzhiev. Licensed under GPL-3.0-only
