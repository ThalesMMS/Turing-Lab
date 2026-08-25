#!/bin/bash

case "${1:-}" in
    --version)
        echo "Flutter fake 1.0"
        exit 0
        ;;
    pub)
        [ "${2:-}" = "get" ] || exit 64
        exit "${FAKE_PUB_EXIT:-0}"
        ;;
    analyze)
        exit "${FAKE_ANALYZE_EXIT:-0}"
        ;;
    test)
        exit "${FAKE_TEST_EXIT:-0}"
        ;;
    build)
        case "${2:-}" in
            apk)
                mkdir -p build/app/outputs/flutter-apk
                printf 'fake-apk\n' >build/app/outputs/flutter-apk/app-release.apk
                echo "Built build/app/outputs/flutter-apk/app-release.apk"
                exit "${FAKE_BUILD_EXIT:-0}"
                ;;
            linux)
                case "$(uname -m)" in
                    x86_64) arch=x64 ;;
                    aarch64|arm64) arch=arm64 ;;
                    *) arch=x64 ;;
                esac
                bundle="build/linux/${arch}/release/bundle"
                mkdir -p "${bundle}/lib" "${bundle}/data"
                printf 'fake-bin\n' >"${bundle}/turing_lab"
                chmod +x "${bundle}/turing_lab"
                printf 'fake-lib\n' >"${bundle}/lib/libflutter_linux_gtk.so"
                printf 'fake-data\n' >"${bundle}/data/icudtl.dat"
                echo "Built ${bundle}"
                exit "${FAKE_BUILD_EXIT:-0}"
                ;;
            web)
                mkdir -p build/web
                printf 'fake-web\n' >build/web/index.html
                echo "Built build/web"
                exit "${FAKE_BUILD_EXIT:-0}"
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
