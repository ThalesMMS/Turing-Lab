#!/bin/bash

case "${1:-}" in
    --version)
        echo "Dart fake 1.0"
        exit 0
        ;;
    format)
        exit "${FAKE_FORMAT_EXIT:-0}"
        ;;
    run)
        case "${2:-}" in
            tool/hard_edge_cases.dart)
                exit "${FAKE_PROPERTIES_EXIT:-0}"
                ;;
            tool/localization_literal_scan.dart)
                exit "${FAKE_LOCALIZATION_SCAN_EXIT:-0}"
                ;;
            tool/localization/check_pseudo_localization.dart)
                exit "${FAKE_PSEUDO_LOCALIZATION_EXIT:-0}"
                ;;
            *)
                exit 64
                ;;
        esac
        ;;
    *)
        exit 64
        ;;
esac
