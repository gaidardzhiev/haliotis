# Abalone

[Slug](https://github.com/gaidardzhiev/slug) is a sequential interpreted programming language. It has a lexer, a recursive descent parser, a tree walking evaluator, an environment model with lexical scoping and closures. It is around a thousand lines of C. You can hold the entire thing in your head, which was always the point. Abalone is Slug running on an Nvidia GPU.

That sentence contains a contradiction worth sitting with. An AST walking interpreter is about the most GPU hostile structure imaginable. Every node waits on the one before it. The evaluation order is fixed by the tree. The environment is a linked list of linked lists threaded through heap pointers. The call stack grows with every function call and shrinks with every return. None of this resembles what a GPU wants to do, which is the same simple operation repeated ten thousand times on ten thousand independent values simultaneously.

## The Insight

A GPU thread stalls when it waits for memory. Pointer chasing through an AST, walking up a chain of environment frames to find a variable, following a linked list of entries to resolve a name: every one of these is a memory access and every memory access on a GPU can cost hundreds of cycles. One interpreter running in one thread spends most of its time stalling.

The GPU hides this cost through a mechanism that has nothing to do with the program and everything to do with the hardware. When one warp stalls, the scheduler switches to another warp at zero cost, because all the register files for all the live warps exist simultaneously. There is no saving and restoring. The registers are just there. The scheduler picks the next ready warp and runs it. If there are enough live warps, the stalls disappear into the background and the execution units stay busy.

An interpreter is full of stalls. So is every other interpreter. If you run thousands of them simultaneously, each stalling at different moments on different memory accesses, you give the hardware exactly the diversity of stall patterns it needs to keep itself occupied. The interpreter's worst property on a single thread becomes its best property across thousands of threads. The thing that made it slow is the thing that makes it fast.

This is not an optimization in the conventional sense. A single Slug program will not evaluate faster on the GPU than on the CPU. What changes is throughput: one program, thousands of inputs, evaluated simultaneously, in the time it takes to run once.


## What Had To Be Solved

The GPU has no operating system. A C program expects one. It expects malloc to return memory, printf to produce output, strcmp to compare strings, exit to terminate the process. None of these exist in device code. Every one of them had to be provided.

Memory allocation uses a per-thread arena. Each execution context gets a flat block of device memory and a bump pointer. Every call to malloc advances the pointer and returns the previous position. Realloc allocates a new block and copies. Free is a no-op against the arena but a free list on top of it catches the common patterns where the same sizes are freed and reallocated repeatedly. The arena is sized before launch and never grows. This is an honest constraint and it is documented.

String functions, the entire surface of string.h that Slug actually touches, are reimplemented as device functions. strlen, strcmp, strncmp, strcpy, strdup, memcpy, memmove, memset. Around two hundred lines, none of it surprising, all of it necessary.

Output uses a per-thread buffer. Every call to outn, Slug's built in print function, writes into a flat character array with a cursor. When the kernel finishes, the host collects each thread's buffer in order and writes it to standard output. The output is deterministic and correctly ordered regardless of how the hardware scheduled the warps.

Error handling uses a per-thread error buffer and a flag. The die and dief functions that terminate the CPU interpreter with a message instead write to the error buffer, set the flag, and return a sentinel value up the call stack. The thread stops. The other threads do not notice.

printf style formatting, the variadic machinery that dief depends on, is emulated with a minimal device side implementation covering the format specifiers that actually appear in Slug's error paths. The va_list mechanism works in modern CUDA with care. The format engine handles %d, %s, %zu, and %c, which is everything Slug uses.

Recursion depth is the most hardware specific constraint. The GPU call stack per thread defaults to 1024 bytes, which is not enough for Ackermann. Before the kernel launches, the host raises the stack limit with a single runtime call. The cost is memory: stack space is allocated for every live thread simultaneously. The tradeoff between thread count and stack depth is explicit in the launch configuration and documented in the build instructions.


## The Correctness Criterion

The output of every Slug script under Abalone must be byte identical to its output under the CPU interpreter. This is the only correctness criterion and it can be checked mechanically. The full script collection is the test suite. It includes the factorial function, the Ackermann function, a general Turing machine simulator encoded in integer arithmetic, Church numerals dissolving the concept of number into pure function application, a Gödel numbering scheme that encodes formulae as integers and applies the diagonal substitution to produce a self-referential sentence, and the halting problem expressed as a stack overflow. The last one terminates the same way on both: the machine runs out of space to contain the contradiction.

If the outputs match, the emulation layer is correct. If they do not, something in the emulation differs from what the operating system provides to the CPU interpreter. The diff is the specification.


## What Abalone Is Not

It is not a general purpose GPU computing framework. It does not ask you to think in warps and blocks and shared memory. It does not expose any GPU primitive to the Slug programmer or to the Slug interpreter. The interpreter does not know it is running on a GPU. The language does not know. The scripts do not know.

It is not a demonstration that sequential interpreters belong on GPUs. They do not, in the sense that a single instance will always be slower. It is a demonstration that the boundary between what runs well on a CPU and what runs well on a GPU is not fixed by the nature of the computation. It is fixed by how many independent instances you have and whether their memory access patterns are diverse enough to keep the warp scheduler occupied. For an interpreter evaluating independent programs, they are.


## The Scripts

The full Slug script collection runs under Abalone without modification. Every script that runs on the CPU interpreter runs on the GPU. Every script that crashes on the CPU interpreter crashes on the GPU, correctly, for the same reason, in its own thread, without affecting the others.

Selected programs that demonstrate what the language can express:  factorial, the simplest recursive function, terminating cleanly at any reasonable depth.

The Ackermann function, which grows faster than any primitive recursive function and requires a stack depth that the default GPU configuration does not provide. It runs correctly after the stack limit is raised.

The Turing machine simulator, which encodes a transition table as a first class function and separates the universal machine from the machine being simulated. The simulator knows nothing about palindromes. The transition function does.

Church numerals, which encode natural numbers as pure function application and implement successor, addition, and multiplication without arithmetic operators. They demonstrate that number is not a primitive but an act.

The Gödel numbering scheme, which assigns numeric codes to logical symbols, encodes formulae as integers, and applies a diagonal substitution to produce a sentence containing its own numeric description. The self-reference is genuine. The arithmetic is a concession to hardware.

The halting problem diagonalization, which produces infinite recursion by construction and terminates in a stack overflow. On the CPU this is a segmentation fault. On the GPU it is a per-thread stack exhaustion that sets the error flag and leaves every other thread running.


## Build

You will need an Nvidia GPU, the CUDA toolkit, and a host C compiler. The target architecture is sm_86, which covers the RTX 3060 Ti and the broader Ampere generation.

The CPU interpreter builds alongside the GPU port. Running slug against a script uses the CPU. Running abalone uses the GPU. The test script runs both against every script in the collection and reports any output that differs.


## The Emulation Layer

The layer that makes Abalone possible is not specific to Slug. Any C program that allocates memory with malloc, reads input at startup, writes output to standard output, and does not fork, handle signals, or spawn threads, can in principle run under the same emulation. The layer knows nothing about interpreters. It knows about memory, strings, output buffers, error handling, and stack depth. Slug happens to need exactly those things and nothing else, which is why the port is clean.

The boundary of what the emulation supports is the boundary of what Abalone supports. It is not a limitation of the approach. It is a property of the hardware and the model, stated plainly rather than hidden.


## License

Copyright (C) 2025, 2026 Ivan Gaydardzhiev. Licensed under GPL-3.0-only; please see [COPYING](./COPYING) for details.
