# Quads Examples

This directory contains example files demonstrating how to use the quads testing framework.

## Files

### example.pl
Traditional monadic quad syntax with various test patterns:
- Simple deterministic tests
- Multiple solutions
- Success/failure tests

Run with:
```bash
scryer-prolog -g "use_module(quads), check_file_quads('example/example.pl'), halt"
```

### binary_example.pl
Binary quad syntax examples (requires patched Scryer Prolog):
- Concise `Goal ?- Answer` format
- Same test patterns as example.pl but in binary syntax

Run with:
```bash
scryer-prolog -g "use_module(quads), check_file_quads('example/binary_example.pl'), halt"
```

### mixed_example.pl
Demonstrates that both monadic and binary syntax can coexist in the same file.

Run with:
```bash
scryer-prolog -g "use_module(quads), check_file_quads('example/mixed_example.pl'), halt"
```

### run_tests.pl
A simple test runner that loads and checks quads from a file.

Modify the `main` predicate to test different files, then run:
```bash
scryer-prolog -g "consult('example/run_tests.pl')"
```

## Expected Output

**Binary quads** emit output for every test:
```
quad(pass, my_append([1,2],[3,4],[1,2,3,4])).
quad(pass, my_length([a,b,c],3)).
```

**Monadic quads** only emit output on failures:
```
quad(fail, Xs=[wrong,answer]).
```

When all tests pass, monadic quads produce no output.
