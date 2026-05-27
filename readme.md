# Haliotis

Haliotis is a general purpose execution environment for sequential C programs on Nvidia GPUs. It takes programs written for a single CPU, with malloc and printf and recursive function calls and pointer-chasing data structures, and runs thousands of them simultaneously on GPU hardware, each isolated from the others, each believing it owns the machine, while the GPU's own scheduler fills every idle cycle with useful work from a context that would otherwise be stalling on a memory access.

The reference implementation is Abalone, which is the Slug interpreter running under Haliotis on the GPU. Slug is a small interpreted programming language, around a thousand lines of C, with a recursive descent parser, a tree-walking evaluator, and an environment model with lexical scoping and closures. It is Turing complete. Abalone takes that interpreter, unmodified in its logic, and runs it on an Nvidia RTX 3060 Ti. Every Slug script, including the Ackermann function, a general Turing machine simulator, Church numerals, a Gödel numbering scheme, and the halting problem expressed as a stack overflow, runs on the GPU and produces output byte-identical to what the CPU interpreter produces. Abalone is the proof that the emulation layer works and the proof that the architecture is sound.


## The Problem Haliotis Solves

Writing for a GPU today means thinking like a GPU. You decompose your problem manually into threads. You manage shared memory explicitly. You insert synchronization barriers at the right points. You choose your block size to maximize occupancy. The programmer does the work that the hardware cannot do for itself, and the result is correct only if the programmer understood the hardware well enough to do that work right.

This model is appropriate for the problems the GPU was designed for: graphics, matrix multiplication, neural network inference, large homogeneous workloads where every thread does the same thing to different data at the same moment. It is the wrong model for the vast majority of programs that exist, which were written by programmers thinking about their problem rather than about warps and memory hierarchies.

Haliotis inverts the relationship. The programmer writes a normal sequential C program. The runtime decides how to map it onto the hardware. The programmer sees an isolated execution environment that behaves like a normal computer. The hardware sees occupancy.


## Why This Works

An RTX 3060 Ti has 38 streaming multiprocessors. Each one can hold up to 1536 threads in flight simultaneously, each with its own live register file. The hardware switches between warps not by saving and restoring registers but because all the register files for all the live warps exist at the same time and the scheduler simply picks which one runs next. This is how the GPU hides memory latency. When one warp stalls waiting for a memory access that takes hundreds of cycles, another warp that is ready runs instead. If there are enough live warps, the stalls disappear into the background and the execution units stay busy continuously.

A sequential C program stalls on memory constantly. Pointer chasing through linked lists, walking up chains of environment frames to find a variable, following a tree of AST nodes during evaluation, allocating and initializing heap blocks: every one of these touches memory and every memory touch is a potential stall of hundreds of cycles. One program in one thread wastes most of those cycles waiting.

Thousands of independent programs running simultaneously, each stalling at different moments on different memory accesses, give the warp scheduler exactly the diversity it needs to keep the machine fully occupied. The thing that makes a sequential interpreter slow in isolation, constant irregular memory access with no predictable pattern, is precisely the thing that makes it effective at filling a GPU when you run enough instances of it at the same time.

This is not an optimization in the conventional sense. A single Slug program will not evaluate faster on the GPU than on the CPU. What changes is throughput: one program, thousands of inputs, evaluated simultaneously, in the time it takes to run once on the CPU.


## The Emulation Layer

A C program expects an operating system beneath it. It expects malloc to return memory, printf to produce output, fopen to open files, strcmp to compare strings, exit to terminate the process. None of these exist in a CUDA kernel. Haliotis provides all of them.

At the bottom is a syscall emulation table: twelve operations that cover everything a well-behaved C program actually asks the operating system to do. Memory allocation and deallocation. Reading and writing through file descriptors. Opening and closing files. Exiting with a status code. Getting the time. These twelve operations are the floor. Everything above them, the entire C standard library surface that programs use, is built on top.

Memory allocation uses a per-context arena. Each execution context receives a flat block of device memory and a bump pointer before the kernel launches. Every call to malloc advances the pointer and returns the previous position. A free list on top of the arena catches freed blocks by size class and reuses them before bumping further. The arena is finite and its size is a compile-time constant. Programs that allocate more than the arena provides will fail with a clean error rather than silently corrupting another context's memory.

String functions, the entire surface of string.h that C programs actually touch, are reimplemented as device functions: strlen, strcmp, strncmp, strcpy, strdup, memcpy, memmove, memset, and the ctype predicates. They are identical in logic to the standard implementations and invisible to the program using them.

Output uses per-context buffers. Every call to printf or puts or fwrite to stdout writes into a flat character array with a cursor. When the kernel finishes, the host collects each context's output buffer in order and writes it to standard output. The output is deterministic regardless of how the hardware scheduled the warps, because collection happens after all contexts finish and is ordered by context index.

The virtual filesystem is populated by the host before the kernel launches. Files the program needs are read on the CPU, copied to device memory, and registered by path. When the program calls fopen, it searches the virtual table by path and receives a file descriptor backed by that device memory. fread advances a cursor through the file data. fwrite to a writable file accumulates output that the host collects after the kernel finishes.

Error handling replaces exit and abort with a per-context flag and a return. When a context calls exit, the flag is set and control returns up the call stack to the kernel, which sees the flag and does not collect output for that context as a successful result. The context terminates. The others do not notice.

The entire redirection is transparent to the program. Under __CUDA_ARCH__, which is defined when nvcc is compiling device code, every standard name is redirected to its Haliotis equivalent through a macro header. The program includes haliotis.h, is compiled with nvcc, and the rest is invisible.


## Two Levels of Scheduling

Haliotis operates with two schedulers working simultaneously, at different levels, for the same purpose: keeping the hardware busy.

The outer scheduler is the GPU's own warp scheduler. It operates at the instruction level, switching between warps with zero overhead whenever one stalls. This is hardware and cannot be influenced directly. It runs continuously and automatically for the entire duration of the kernel.

The inner scheduler is implemented by Haliotis in device code. It operates at the program level, switching between execution contexts when a context reaches a natural yield point such as a statement boundary, a function call, or a memory allocation. When a context yields, the scheduler saves its position and runs the next ready context in the pool assigned to that GPU thread. This means each GPU thread is not running one program to completion but is instead interleaving the execution of a small pool of programs, switching between them whenever one pauses.

The two schedulers compose. The inner scheduler ensures that each GPU thread always has a ready context to execute, which keeps the thread from going idle at the program level. The outer scheduler ensures that each SM always has a ready warp to execute, which keeps the execution units from going idle at the hardware level. The result is maximum occupancy from programs that were never written to produce it.


## What Haliotis Is

It is a GPU process namespace manager. Each namespace is an isolated execution context with its own virtual machine state: its own memory, its own file descriptors, its own output, its own error stream, its own clock, its own exit status. The manager is the runtime that maps namespaces onto warps, allocates their memory from a global pool, provides their filesystem and IO through the emulation layer, schedules between them at yield points, and collects their output when they finish.

It is also an operating system in miniature, running in device code, on hardware that was built for a completely different programming model. It does not restructure the programs it runs. It does not analyze them or transform them. It provides the environment they expect and lets them run, exploiting the fact that independent sequential programs stall on memory at different times, which is precisely what the GPU's latency hiding mechanism was designed to absorb.

The isolation between contexts is structural rather than enforced. Each context has its own memory. There is no shared mutable state between them unless you explicitly arrange for it. A crash in one context, a division by zero, a stack overflow, a runaway allocation that exhausts the arena, does not affect any other context. The others finish and their output is collected normally. This is a stronger isolation guarantee than running the same program in parallel processes on a CPU, where the processes share a kernel, a filesystem, and potentially a memory cache. Under Haliotis the isolation is a consequence of the hardware model, not a policy imposed on top of it.


## Abalone

Abalone is Slug running under Haliotis. It is the project that proved the architecture works before the architecture was fully generalized.

Slug is a complete small programming language. It has a lexer that tokenizes source text into a dynamic vector of tokens, a recursive descent parser that builds a heap-allocated AST, an environment model implemented as linked lists of linked lists threaded through parent pointers, and a tree-walking evaluator that recurses through the AST calling itself for every node. Every one of these structures is GPU-hostile: dynamic allocation throughout, pointer chasing at every step, recursion of unbounded depth. Porting Slug to the GPU under Haliotis was the hardest possible test of whether the emulation layer was sufficient.

The Slug scripts that run under Abalone include programs that press against the edges of what the language can express. The factorial function as a baseline. The Ackermann function, which grows faster than any primitive recursive function and requires deep recursion that tests the configured stack limit. A general Turing machine simulator that separates the universal machine from the transition function, passing the latter as a first-class value. Church numerals that encode natural numbers as pure function application and implement arithmetic without arithmetic operators. A Gödel numbering scheme that assigns integer codes to logical symbols, encodes formulae as integers, and applies a diagonal substitution to produce a sentence containing its own numeric description. And the halting problem diagonalization, which produces infinite recursion by construction and terminates in a stack overflow on both the CPU and the GPU, correctly, for the same reason.

The correctness criterion for Abalone is simple and mechanical. Run every script under the CPU interpreter. Run every script under Abalone. Diff the outputs. If they are identical, the emulation layer is correct. The verification script in abalone/verify.sh does exactly this and reports the result for every script individually before summarizing.


## What Haliotis Supports

A C program runs under Haliotis if it reads its input at startup rather than waiting for it interactively, writes its output to standard output or files, allocates memory with bounded total usage per run that fits within the configured arena, and does not fork, handle signals, spawn threads of its own, or dynamically load libraries.

This is a large class. It includes interpreters, parsers, compilers, graph algorithms, simulations, symbolic mathematics, recursive computations, and any program that can be described as a pure function from input to output with bounded memory. The boundary of what does not fit is architectural rather than arbitrary: the GPU thread model does not compose with forking or signal handling or dynamic linking, and no amount of emulation changes that.

The most valuable application of the supported class is batch execution. One program, ten thousand inputs, the time it takes to run it once. Fuzzing an interpreter against a corpus of programs. Testing a parser against a corpus of inputs. Running a simulation over a sweep of initial conditions. Any workload that requires running the same computation many times with different starting conditions runs naturally under Haliotis without any modification to the program being run.


## What This Is For, Beyond The Obvious

The throughput argument is clear and was stated above. The less obvious argument is about isolation. A program that might crash on certain inputs, that might consume unexpected memory, that might loop indefinitely, can be run under Haliotis at scale without any one bad input affecting any other. The boundary between contexts is hard and structural. This makes Haliotis appropriate for running untrusted or unstable programs, for fuzzing, for differential testing against a reference implementation, for any situation where you want to run a program many times and know that the runs are genuinely independent.

The most interesting argument is the one that is hardest to state without sounding like a claim about something other than engineering. The boundary between what runs on a CPU and what runs on a GPU is not fixed by the nature of computation. It is fixed by the assumptions that execution environments make about the hardware beneath them. A sequential C program runs on a CPU because that is what sequential C programs are compiled for, not because sequential computation is intrinsically CPU-bound. Haliotis changes the execution environment and the program runs on the GPU. The computation is the same. The hardware is different. The output is identical.


## Status

The emulation layer covering the memory subsystem, string functions, formatted output, virtual filesystem, IO, and process control is implemented and verified against the Abalone test suite. The cooperative inner scheduler is the current focus of development. The preparation tool that automates porting arbitrary C programs to the Haliotis compilation pipeline handles the common cases and requires manual annotation for the rest.

What is not yet complete is documented here rather than silently absent. Full libc coverage beyond what Abalone requires is in progress. The prep tool will be extended to handle the annotation cases automatically using a Clang AST pass. The cooperative scheduler, once complete, will be validated by measuring occupancy improvement against the baseline single-context-per-thread model.


## License

Copyright (C) 2025, 2026 Ivan Gaydardzhiev. Licensed under GPL-3.0-only; please see [COPYING](./COPYING) for details.
