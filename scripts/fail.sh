#!/usr/bin/env bash

function fail {
    printf '%s\n' "$1" >&2
    exit "${2-1}"
}
