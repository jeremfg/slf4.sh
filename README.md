# slf4sh

Simple Logging Facade for Shell

## Install

### Using [bpkg (Bash Package Manager)](https://bpkg.sh/)

```bash
bpkg install jeremfg/slf4.sh
```

or

```bash
bpkg install -g jeremfg/slf4.sh
```

NOTE: bpkg itself can easily be installed by calling
`curl -sLo- https://get.bpkg.sh | bash`

In the first case, the library is installed local to your project.
You will need to `source deps/slf4.sh/src/slf4.sh`.
In the second case, the library is installed globally.
You will need to `source ~/.local/lib/slf4.sh`.

## Features

Provides the following functions:

```bash
logTest()
logTrace()
logDebug()
logInfo()
logWarn()
logError()
logFatal()

logSetLevel()
```

You can either pass your log message as an argument,
or pipe straight into it. See examples below:

```bash
logWarn "An error occured on $(hostname)"

logError <<EOF
This is a detailed bug report
$(date)
$(hostname)

A lot of stuff happened!
EOF
```

## Setup for developers

Once you've checked out this repository call the following:

```bash
./tool/setup
```

### Release

To create a release, call

```bash
./tool_release <version>
```

Where `<version>` is a semantic version 2.0.0 version number

## TODO

- [ ] Document using shdoc: <https://github.com/reconquest/shdoc>

## Features being considered

- [ ] Add color per log level
- [ ] Add PÎD (Process ID) to the printed message metadata
