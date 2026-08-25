#!/bin/bash

case "${1:-}" in
    --version)
        echo "Dart fake 1.0"
        exit 0
        ;;
    format)
        exit "${FAKE_FORMAT_EXIT:-0}"
        ;;
    *)
        exit 64
        ;;
esac
