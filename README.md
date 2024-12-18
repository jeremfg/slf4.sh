# slf4sh

Simple Logging Facade for Shell

## Install

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

[ ] Document using shdoc: <https://github.com/reconquest/shdoc>
[ ] Package releases with BPKG: <https://bpkg.sh/>

## Features being considered

[ ] Add color per log level
[ ] Add PÎD (Process ID) to the printed message metadata
