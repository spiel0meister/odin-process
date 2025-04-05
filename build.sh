#!/usr/bin/env bash

set -ex

odin build examples/example1 -debug
mv example1 examples/example1/

odin build examples/example2 -debug
mv example2 examples/example2/

