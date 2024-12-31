# tests

via [BATS:Bash Automated Testing System][bats-core].

## install 

macOS:

```bash
brew install bats-core
```

## run

```bash 
$ bats --verbose-run --pretty -r test
```

## guidelines

- 1 test file per [porcelain function][porcelain].
- just test the happy path & at least 1 edge case.
- avoid mocking *entirely*, if possible.

> stupidly simple & clutter-free test files **>** exhaustive testing.

### author

[@nicholaswmin][author-gh]

<!-- links -->

[author-gh]: https://github.com/nicholaswmin
[bats-core]: https://github.com/bats-core/bats-core
[porcelain]: https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain
