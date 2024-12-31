# tests

via [BATS].

## install 

```bash
brew install bats-core
```

## run

```bash 
$ bats test
```

## guidelines

- 1 test file per [porcelain function][porcelain].
- test the happy path & at least 1 edge case.
- avoid mocking.

> simple test files **>** exhaustive testing.

### author

[@nicholaswmin][author-gh]

<!-- links -->

[author-gh]: https://github.com/nicholaswmin
[bats-core]: https://github.com/bats-core/bats-core
[porcelain]: https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain
