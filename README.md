# Quads: Literate Testing Framework for Scryer Prolog

A generic package for writing literate tests using quad tests (query-answer pairs) in Scryer Prolog source files.

## ⚠️ Disclaimer

This code was written in a hurry, out of a need for efficiency, not out of love. Though that may change one day.

This is a "vibe coding" project - built quickly to solve an immediate need. Use at your own risk, but feel free to contribute improvements!

## What are Quad Tests?

Quad tests are a literate testing style where you write queries and their expected answers directly in your Prolog source files. The testing framework reads these pairs and verifies that the queries produce the expected results.

A "quad" consists of:
1. A query: `?- Goal.`
2. An answer description: the expected result

### Monadic Quad Syntax (Traditional)

```prolog
?- my_append([1,2], [3,4], Xs).
   Xs = [1,2,3,4].
```

### Binary Quad Syntax (Experimental)

Inspired by [Ulrich Neumerkel's length_quad.pl](https://www.complang.tuwien.ac.at/ulrich/iso-prolog/length_quad.pl), we're working on supporting a more concise binary syntax:

```prolog
'test of my_append([1,2], [3,4], Xs)' ?- my_append([1,2], [3,4], Xs).
   Xs = [1,2,3,4].
```

**⚠️ Status**: Binary quad syntax **does not currently work** with standard Scryer Prolog. It requires a patched version that has not yet been merged upstream. See the Roadmap section below for details on the patch.

## Installation

### Prerequisites

Ensure `SCRYER_PATH` is set in your environment. This tells Scryer Prolog where to find library modules:

```bash
export SCRYER_PATH=/path/to/scryer_libs
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it permanent.

### Using Bakage (Recommended)

Bakage is a package manager for Scryer Prolog. If you don't have it, get it from https://github.com/bakaq/bakage

1. Add to your `scryer-manifest.pl`:

```prolog
dependencies([
    dependency("quads", git("https://github.com/jjtolton/quads.git"))
]).
```

2. Install dependencies:
```bash
bakage install
```

3. Bakage will install packages to `./scryer_libs` in your project directory. Make sure `SCRYER_PATH` points to this directory:

```bash
export SCRYER_PATH=$(pwd)/scryer_libs
```

### Manual Installation

Copy the `quads.pl` file into your project or to a directory in your `SCRYER_PATH`:

```bash
# Option 1: Copy to project
cp quads.pl /path/to/your/project/

# Option 2: Add to SCRYER_PATH
mkdir -p ~/scryer_libs/quads
cp quads.pl ~/scryer_libs/quads/
export SCRYER_PATH=~/scryer_libs
```

## Usage

### Writing Quad Tests

Embed quad tests directly in your Prolog source files. Each quad consists of a query followed by its expected answer:

```prolog
my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :-
    my_append(Xs, Ys, Zs).

% Simple deterministic test
?- my_append([1,2], [3,4], Xs).
   Xs = [1,2,3,4].

% Test with multiple solutions
?- my_append(Xs, Ys, [1,2,3]).
   Xs = [], Ys = [1,2,3]
;  Xs = [1], Ys = [2,3]
;  Xs = [1,2], Ys = [3]
;  Xs = [1,2,3], Ys = [].

% Test that should succeed
?- my_append([a], [b], [a,b]).
   true.

% Test that should fail
?- my_append([1], [2], [1,2,3]).
   false.
```

### Running Tests

```prolog
:- use_module(library(quads)).

main :-
    check_file_quads('my_file.pl'),
    halt.
```

Run it:
```bash
scryer-prolog -g main
```

### Output

**Binary quads** always emit output:
```
quad(pass, my_append([1,2],[3,4],[1,2,3,4])).
quad(fail, my_append([1,2],[3,4],[9,9,9])).
```

**Monadic quads** only emit on failure:
```
quad(fail, Xs=[wrong,answer]).
```

## API

### check_module_quads/1
```prolog
check_module_quads(+Module)
```
Load and check all quad tests in a module. The module file must be `Module.pl`.

### check_module_quads/2
```prolog
check_module_quads(+Module, -Quads)
```
Like `check_module_quads/1` but also returns the list of quads.

### check_file_quads/1
```prolog
check_file_quads(+File)
```
Check all quad tests in a file.

### check_file_quads/2
```prolog
check_file_quads(+File, -Quads)
```
Like `check_file_quads/1` but also returns the list of quads.

## Answer Description Formats

### Deterministic (single answer)
```prolog
?- length([1,2,3], N).
   N = 3.
```

### Multiple specific answers
```prolog
?- member(X, [1,2,3]).
   X = 1
;  X = 2
;  X = 3.
```

### Infinite or many solutions
Use `...` to indicate more solutions exist:
```prolog
?- length(Xs, 2).
   Xs = [_A,_B]
;  ... .
```

### Success test
```prolog
?- append([1], [2], [1,2]).
   true.
```

### Failure test
```prolog
?- member(4, [1,2,3]).
   false.
```

## Roadmap

### Binary Quad Syntax Support

Inspired by [Ulrich Neumerkel's work](https://www.complang.tuwien.ac.at/ulrich/iso-prolog/length_quad.pl), we're adding support for a more compact binary quad syntax:

**Traditional (Monadic)**:
```prolog
?- my_pred(X).
   X = value.
```

**New (Binary)**:
```prolog
'test of my_pred(X)' ?- my_pred(X).
   X = value.
   
%% or

'test of my_pred(X)' 
?- my_pred(X).
   X = value.
```

#### Current Status

- ✅ Quads module ready to process both syntaxes
- ✅ Binary quads will emit: `quad(pass, Goal)` or `quad(fail, Goal)`
- ✅ Monadic quads emit: `quad(fail, Answer)` on failure only
- ❌ **Binary syntax does not work yet** - requires Scryer Prolog patch (see below)

#### Scryer Prolog Patch (Required for Binary Quads)

Binary quad syntax **currently does not work** with standard Scryer Prolog. To use it, you need a patched version:

**Patch Location**: Branch `binary-quad-syntax` at https://github.com/jjtolton/scryer-prolog
**Upstream PR**: [#3132](https://github.com/mthom/scryer-prolog/pull/3132) - Add binary quad syntax support (proof of concept)
**Based on**: Scryer Prolog upstream master
**Changes**:
1. `src/loader.pl` - Skip binary quad terms and their answer descriptions during loading
2. `src/parser/ast.rs` - Define `?-` as infix operator (xfx, 1200)

**Why needed**: Without the patch, Scryer tries to compile `Goal ?- Answer` as regular clauses, causing `permission_error(modify,static_procedure)` errors.

**Status**:
- ✅ Patch is ready and tested
- ✅ PR submitted to upstream (see [#3132](https://github.com/mthom/scryer-prolog/pull/3132))
- ⏳ Awaiting review and potential merge
- Once merged into Scryer Prolog, binary quads will work out of the box

**Note**: The PR is submitted as a proof-of-concept. The Scryer maintainers may choose to reimplement the feature differently.

**For now**: Use only the monadic quad syntax (`?- Goal` followed by `Answer`) which works with all versions of Scryer Prolog.

### Future Plans

- [ ] Configurable output modes (silent, verbose, TAP format)
- [ ] Integration with CI/CD workflows
- [ ] Performance benchmarks
- [ ] Documentation generation from quads
- [ ] Support for property-based testing patterns

## Example

See the `example/` directory for complete working examples of both monadic and binary quad syntax.

## Credits

- Based on the quadtests framework from [Scryer Prolog's numerics library](https://github.com/mthom/scryer-prolog/blob/master/src/lib/numerics/quadtests.pl)
- Binary quad syntax inspired by [Ulrich Neumerkel's length_quad.pl](https://www.complang.tuwien.ac.at/ulrich/iso-prolog/length_quad.pl)
- Additional inspiration from [@dcnorris](https://github.com/dcnorris) and the numerics/quads work
- Adapted into a generic reusable package by Jay Tolton

## License

MIT License - See LICENSE file for details
