# SLUG

Slug is a minimalist, interpreted programming language written in C. It features a lexical analyzer, parser, environment management, and an interpreter capable of evaluating expressions and statements including control flow, functions, and recursion.

Designed to be simple yet powerful, Slug supports higher order functions, closures, conditionals, and looping constructs. Through examples such as the factorial function, the deeply recursive Ackermann function, and advanced recursion patterns, Slug demonstrates its ability to express any computable function and is therefore **Turing complete**.

Slug is suitable for exploring language interpreter design, functional programming concepts, and computational theory in a compact and clear environment.


## Features

- Lexical tokenizer supporting keywords, identifiers, literals, operators, and symbols.
- Recursive descent parser producing an Abstract Syntax Tree (AST).
- Environment model with variable scoping and constants.
- Primitive data types: numbers and booleans.
- Functions.
- Control flow constructs: `if`, `elif`, `else`, `while`.
- Built in output function `outn` for printing values.
- Runtime error handling with descriptive messages.
- Interpreter that evaluates the AST directly.


## Language Overview

The language supports:

- Variable declarations with `var` and `const`.
- Arithmetic operators (`+`, `-`, `*`, `/`, `%`).
- Comparison and equality operators (`<`, `<=`, `>`, `>=`, `==`, `!=`).
- Logical operators (`&&`, `||`, `!`).
- Function declarations via `func(params) => expression`.
- Control structures: `if`, `elif`, `else`, `while`.
- Statements end with semicolons `;`.
- Output via `outn(expression);`.


## Code Structure

### Tokenizer

Converts source text into tokens for keywords, identifiers, literals, operators, and punctuation.

### Parser

Implements recursive descent to produce an AST representing the program structure, supporting expressions, statements, blocks, and functions.

### AST Nodes & Types

Enumerates node types and expresses program structure:
- Literals (number, boolean)
- Identifiers
- Variable declarations (`var`, `const`)
- Assignments
- Binary and unary operations
- Blocks (`{ ... }`)
- Control flow (`if/elif/else`, `while`)
- Function declarations and calls
- Built in function calls (currently `outn`)

### Runtime Environment

Linked list environment with support for nested scopes, variable binding, constants, and lookup.

### Values

Supports numbers, booleans, functions (closures), and null.

### Interpreter

Walks the AST to evaluate expressions and statements:

- Evaluates literals and identifiers.
- Variable declaration and assignment with constant checks.
- Arithmetic and logical operations with type checking.
- Control flow execution (`if/elif/else`, `while`).
- Function calls with closure environments.
- Built in `outn` prints evaluated values.

Errors (e.g., undefined variables, type mismatches, division by zero) cause the interpreter to print a descriptive message and terminate.


## Slug Language: Features and Turing Completeness Proof

This document describes several scripts and core language features of the Slug interpreted programming language, demonstrating its capabilities and proving it is Turing complete.


## Core Language Features

### Arithmetic, Variables, and Conditionals (`scripts/core_language_test.slg`)
```js
{
    var a = 10;
    const b = 5;
    var c = a + b * 2;
    outn(c);

    if (c > 15) {
        outn(1);
    } elif (c > 10) {
        outn(2);
    } else {
        outn(3);
    }

    var count = 0;
    while (count < 5) {
        outn(count);
        count = count + 1;
    }

    var multiply = func (x, y) => {
        x * y;
    };

    var result = multiply(4, 5);
    outn(result);

    var outer = func (x) => {
        func (y) => {
            x + y;
        };
    };
    var add5 = outer(5);
    outn(add5(10));

    var val = true && false || true;
    if (val == true) {
        outn(42);
    }
}
```

- Supports variables (mutable `var` and immutable `const`).
- Arithmetic operations and operator precedence.
- Conditional `if`, `elif`, and `else` blocks.
- Loops using `while`.
- Function declarations, including closures and nested functions.
- Boolean logic operations.


### Simple Recursion (`scripts/turing.slg`)
```js
var factorial = func(n) => {
    if (n == 0) {
        1;
    } else {
        n * factorial(n - 1);
    }
};

var result = factorial(5);
outn(result);
```
- Demonstrates recursion and function calls.
- Computes factorial demonstrating non trivial mathematical functions.


### Anonymous Functions (`scripts/anon_func.slg`)
```js
var increment = func(x) => { x + 1; };
outn(increment(7));
```
- Supports anonymous functions (lambdas).
- Direct application of function values.


### Advanced Recursion: Ackermann Function (`scripts/ackermann.slg`)
```js
var ackermann = func(m, n) => {
    if (m == 0) {
        n + 1;
    } else {
        if (n == 0) {
            ackermann(m - 1, 1);
        } else {
            ackermann(m - 1, ackermann(m, n - 1));
        }
    }
};

var result = ackermann(3, 7);
outn(result);
```
- A classic computationally intensive recursive function.
- Demonstrates deep recursion and complex control flow capabilities.
- Running this successfully shows the language supports computations beyond simple loops.


### Loop Control without break (`scripts/unbounded_loop.slg`)
```js
var i = 0;
var done = false;
while (!done) {
    i = i + 1;
    if (i == 10) {
        outn(i);
        done = true;
    }
}
```
- Demonstrates looping and condition controlled termination without `break`.
- Shows language handles boolean variables and `while` loops effectively.


### Higher Order Functions and Closures (`scripts/higher_order_functions_and_closures.slg`)
```js
var apply = func(f, x) => {
    f(x);
};

var square = func(n) => {
    n * n;
};

outn(apply(square, 5));
```
- Supports functions as first class values.
- Demonstrates passing functions as arguments and returning values.


### Tail Recursive Function (`scripts/recursion.slg`)
```js
var fact = func(n, acc) => {
    if (n == 0) {
        acc;
    } else {
        fact(n - 1, acc * n);
    }
};

outn(fact(5, 1));
```
- Shows support for tail recursion style functions with parameters as accumulators.
- Demonstrates ability to write efficient recursive code patterns.


### Truth Tables (`scripts/truth_table_testing.slg`)
```js
var not = func(b) => {
        if (b) { false; } else { true; }
};

var and = func(a, b) => a && b;
var or = func(a, b) => a || b;

var get_bit = func(num, bit) => {
        if ((num / bit) % 2 == 0) { false; } else { true; }
};

var truth_table = func(f) => {
        var i = 0;
        while (i < 4) {
                var a = get_bit(i, 2);
                var b = get_bit(i, 1);
                outn(f(a, b));
                i = i + 1;
        }
};

var de_morgan_1 = func(a, b) => {
        not(and(a, b)) == or(not(a), not(b));
};

truth_table(de_morgan_1);
```
- Defines basic boolean logic functions `not`, `and`, `or`.
- Programmatically generates all possible Boolean input pairs using `get_bit`.
- Automates truth table testing with the `truth_table` function by evaluating `f` over all input pairs.
- Tests De Morgan's Law, outputting `true` or `false` for each case.


### De Morgan's Law (`scripts/demorgan_law.slg`)
```js
var not = func(b) => {
    if (b) { false; } else { true; }
};

var and = func(a, b) => { a && b; };
var or = func(a, b) => { a || b; };

var de_morgan_1 = func(a, b) => {
    not(and(a, b)) == or(not(a), not(b));
};

outn(de_morgan_1(true, true));
outn(de_morgan_1(true, false));
outn(de_morgan_1(false, true));
outn(de_morgan_1(false, false));
```
- Implements the boolean negation, AND, and OR functions.
- Defines the De Morgan equivalence function `de_morgan_1`.
- Outputs the result of the equivalence on all possible two boolean inputs manually.
- Demonstrates the fundamental logic identity holds for every input.


### Halting Paradox (`scripts/halting_paradox.slg`)
```js
var halts = func(prog, input) => {
    false;
};

var diagonal = func(f) => {
    if (halts(f, f)) {
        diagonal(f);
    } else {
        0;
    }
};

var paradox = func(haltFunc) => {
    diagonal(haltFunc);
};

var result = paradox(diagonal);

outn(result);
```
- Defines a false halting oracle `halts` always returning `false`.
- Defines `diagonal` applying oracle to function applied to itself, recursing infinitely if halting predicted.
- Sets up `paradox` to apply `diagonal` to a halting oracle itself.
- Outputs `0`, illustrating the contradiction proving halting problem undecidable.

### Halting Problem Diagonalization (`scripts/pure_diag.slg`)
```js
var loops = func(f) => {
    if (f(loops)) {
        loops(loops);
    } else {
        0;
    }
};

outn(loops(loops));
```

**Result**: Segmentation fault (stack overflow)

This implements the diagonalization argument from Turing's halting problem proof. The `loops` function receives itself as input and behaves oppositely to its own prediction:

- If `loops(loops)` halts, it takes the `else` branch and returns `0`
- If `loops(loops)` loops, it takes the `if` branch and recurses

The contradiction forces infinite recursion, exhausting the call stack until the interpreter crashes. This demonstrates the halting problem's undecidability empirically through stack overflow.

**Significance**: Confirms the language can express self referential constructions that prove fundamental computability limits.

### Church Numerals (`scripts/church_numerals.slg`)
```js
var zero  = func(f, x) => x;
var one   = func(f, x) => f(x);
var two   = func(f, x) => f(f(x));
var three = func(f, x) => f(f(f(x)));

var succ = func(n, f, x) => f(n(f, x));
var add  = func(m, n, f, x) => n(f, m(f, x));
var mul  = func(m, n, f, x) => n(func(y) => m(f, y), x);

var to_int = func(n) => n(func(x) => x + 1, 0);

var four  = func(f, x) => succ(three, f, x);
var five  = func(f, x) => add(two, three, f, x);
var six   = func(f, x) => mul(two, three, f, x);
var seven = func(f, x) => succ(func(g, y) => add(three, three, g, y), f, x);

outn(to_int(zero));
outn(to_int(one));
outn(to_int(four));
outn(to_int(five));
outn(to_int(six));
outn(to_int(seven));
```
- Encodes natural numbers as pure functions where a number `n` represents applying `f` to `x` exactly `n` times.
- Implements `succ`, `add`, and `mul` entirely through function composition, with no arithmetic operators.
- Defines `to_int` as the only bridge to numeric values, by substituting `f` with increment and `x` with zero.
- Demonstrates that numbers do not need to be language primitives, computation itself can encode quantity.

> **Note:** The canonical Church encoding uses currying, a number is a function waiting for `f`, returning a function waiting for `x`. Slug's lack of curried function returns forces all parameters into one call, which obscures that relationship. Slug can express the computation but cannot represent the concept cleanly. **This is the direct consequence of bad language design...**

### Collatz Conjecture (`scripts/collatz.slg`)
```js
var even = func(n) => n % 2 == 0;

var collatz = func(n, steps) => {
    if (n == 1) {
        steps;
    } else {
        if (even(n)) {
            collatz(n / 2, steps + 1);
        } else {
            collatz(n * 3 + 1, steps + 1);
        }
    }
};

outn(collatz(27, 0));
```
- Defines the Collatz sequence: halve if even, multiply by 3 and add 1 if odd, repeat until reaching 1.
- Counts steps using the accumulator pattern, terminating only when `n` reaches 1.
- Outputs 111, the number of steps for input 27, a deceptively large count for such a small number.
- The conjecture is unproven: no one knows if this function halts for all inputs.

### General Turing Machine Simulator (`scripts/palindrome_checker.slg`)
```js
var tape_read  = func(right) => right % 10;
var tape_write = func(right, s) => (right / 10) * 10 + s;
var move_right = func(left, right) => left * 10 + right % 10;
var move_left  = func(left, right) => right * 10 + left % 10;

var get_state  = func(triple) => triple / 100;
var get_write  = func(triple) => (triple / 10) % 10;
var get_dir    = func(triple) => triple % 10;

var run = func(transition, state, left, right) => {
    if (state == 4) {
        1;
    } else {
        if (state == 5) {
            0;
        } else {
            var symbol = tape_read(right);
            var triple = transition(state, symbol);
            var new_state = get_state(triple);
            var new_right = tape_write(right, get_write(triple));
            if (get_dir(triple) == 1) {
                run(transition, new_state, move_right(left, new_right), new_right / 10);
            } else {
                run(transition, new_state, left / 10, move_left(left, new_right));
            }
        }
    }
};
```
- Implements a general Turing machine simulator using two integers as the tape, `left` holds digits to the left of the head, `right` holds digits to the right, with the least significant digit of `right` always under the head.
- Encodes each transition as a single integer triple `new_state * 100 + write * 10 + direction`, allowing any transition table to be expressed as a pure function passed to `run`.
- Demonstrates that Slug's first class functions are expressive enough to separate the universal machine from the machine being simulated, `run` knows nothing about palindromes, it only knows how to step.
- Instantiates the simulator with a palindrome checker over the alphabet `{1, 2}` with blank `3`, using 8 states to implement the classical erase and compare strategy.
- Outputs `1` for accept and `0` for reject across six test cases covering odd length palindromes, even length palindromes, single symbols, and non palindromes.

> **Note:** The tape is bounded by the size of an integer, Slug has no arbitrary precision arithmetic, so the simulator is a finite approximation of a true Turing machine. It is however philosophically complete: the architecture is correct, the separation between universal machine and transition function is genuine, and any computable function expressible within the integer tape limit can be simulated by passing a different transition function to `run`.

### Gödel Numbering and Diagonalization (`scripts/godel.slg`)
```js
var power = func(b, e) => {
    if (e == 0) { 1; }
    else { b * power(b, e - 1); }
};

var length = func(n) => {
    if (n < 10) { 1; }
    else { length(n / 10) + 1; }
};

var get_symbol = func(n, i) => {
    (n / power(10, i)) % 10;
};

var substitute = func(f, v, pos, acc, mul) => {
    if (pos >= length(f)) {
        acc;
    } else {
        var sym = get_symbol(f, pos);
        if (sym == 7) {
            substitute(f, v, pos + 1, acc + v * mul, mul * power(10, length(v)));
        } else {
            substitute(f, v, pos + 1, acc + sym * mul, mul * 10);
        }
    }
};

var diagonal = func(f) => {
    substitute(f, f, 0, 0, 1);
};

var godels_formula = 157;
var godels_sentence = diagonal(godels_formula);

outn(godels_formula);
outn(godels_sentence);
outn(length(godels_sentence));
outn(get_symbol(godels_sentence, 0));
outn(get_symbol(godels_sentence, 1));
outn(get_symbol(godels_sentence, 2));
outn(get_symbol(godels_sentence, 3));
outn(get_symbol(godels_sentence, 4));
```
- Assigns numeric codes to logical symbols, `1` for zero, `5` for equality, `7` for variable, and encodes formulae as integers stored least significant digit first, so that each digit position corresponds to one symbol in the expression.
- Implements `substitute` to walk a formula digit by digit, replacing every occurrence of the variable marker `7` with an arbitrary numeric value while preserving the positional encoding of all surrounding symbols.
- Applies `diagonal` to formula `157`, encoding `var = 0`, substituting the formula's own Gödel number into itself, producing `15157`, the self referential sentence `var = 0 = 0`.
- Decodes and prints each symbol of the resulting sentence, confirming that the original formula's number `157` is embedded within the sentence at positions 0 through 2.

> **Note:** This is a positional encoding rather than the classical prime exponentiation scheme, Gödel's original construction assigns each symbol a prime and encodes sequences as products of prime powers, guaranteeing unique decodability through factorization. That encoding grows super exponentially and exceeds 32bit integer bounds for all but the shortest formulae. The positional scheme used here sacrifices that uniqueness guarantee in exchange for computational tractability, but preserves the essential mechanism: the diagonal function that produces a statement containing its own numeric description is structurally identical whether the encoding is positional or exponential. The self reference is genuine. The arithmetic is a concession to hardware.


## Proof of Turing Completeness

Slug language supports:

- **Mutable state (variables)**
- **Conditional branching** (`if`, `else`, `elif`)
- **Loops** (`while`)
- **Function definitions, recursion, and higher order functions**

By these properties alone, it meets the minimal criteria to be Turing complete.

Furthermore, the implementation of:

- The **factorial function** (`scripts/turing.slg`),
- The **Ackermann function** (`scripts/ackermann.slg`), and
- Tail recursion with accumulators (`scripts/recursion.slg`),

demonstrate the ability to compute any computable function given enough memory and time.

These scripts prove Slug can simulate the core logic patterns of a Turing machine, thereby being **Turing complete**.

## Conclusion

Slug is a fully featured interpreted language with all fundamental capabilities necessary for general computation.

The advanced recursion and higher order function examples prove its ability to express any computable function, fulfilling the definition of Turing completeness.

A deeper pattern runs through the full script collection. The diagonalization argument in `pure_diag.slg`, the self referential paradox in `halting_paradox.slg`, the undecidability construction in `entscheidungs_problem.slg`, the diagonal substitution in `godel.slg`, and the transition function passed to itself in `palindrome_checker.slg` are all expressions of the same underlying construction, a system applying a description of itself to itself. The Church numerals in `church_numerals.slg` push this further still, demonstrating that even the concept of number is not primitive but can be dissolved entirely into the act of self application. Turing, Gödel, and Church each approached this structure from the vantage point of their own discipline, computability, formal logic, and the foundations of mathematics respectively. The scripts in this collection arrive at it from yet another: the irreducible minimum of a working interpreter.

The one construction this collection cannot express is a **quine**, a program that produces its own source code as output, and whose output is itself a valid program capable of doing the same indefinitely. A quine demands precisely what Slug lacks: the ability to treat syntactic structure as a manipulable value. The diagonal mechanism is already present, as `godel.slg` demonstrates, the substitution of a formula's own numerical encoding into itself is structurally identical to what a quine must do with text. The missing primitive is the string: without string literals, concatenation, and textual output, source code cannot become data, and the reflexive loop cannot close. These three additions to the language would unlock not merely quines, but a proper computational account of Gödel's construction and the full expressive class of self referential programs, all consequent upon a single extension to the type system.

The boundary of what Slug can express turns out to be precisely the boundary between numbers and text.

---

## License

Copyright (C) 2025-2026 Ivan Gaydardzhiev. Licensed under GPL-3.0-only; see [COPYING](./COPYING) for details.
