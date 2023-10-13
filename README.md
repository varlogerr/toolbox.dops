# <a id="top"></a>Shlib

Description

* [Quick demo](#quick-demo)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Development notes](#usage)

## Quick demo

```sh
# quick demo commands
```

[To top]

## Requirements

* `bash`
* `mktemp` (GNU)

[To top]

## Installation

Installation instructions

[To top]

## Usage

Usage instructions

[To top]

## Development notes

### Important

* NEVER use shell expansion like `$'\n'`, it can lead to invalid code after compilation. Instead of `$'\s'` use `${SHLIB_NL}`

### Tags

#### Tags demo

```sh
# Spaces are ignored
# 
# {{ TAG_NAME[ = SELECTOR] }} {{/ TAG }}
# 
# {{ TAG_NAME[=SELECTOR] }}
#   TAG_BODY
# {{/ TAG }}
```

[To top]

#### Shlib specific tags

```sh
# {{ SHLIB_EXTERNAL }} {{/ SHLIB_EXTERNAL }}
```

Compiler will send the module to `# {{ EXTERNAL }} {{/ EXTERNAL }}` marker in the `shlib.tpl.sh`.

```sh
# {{ SHLIB_KEEP = WHATEVER_MARKER }}
  # Something to keep
# {{/ SHLIB_KEEP }}
```

Contents under `SHLIB_KEEP` will get to `{{ WHATEVER_MARKER }}` in `shlib.tpl.sh`, good for variables and other states.


[To top]

[To top]: #top
