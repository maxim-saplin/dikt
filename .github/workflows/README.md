1. web_build_publish - builds web version and published to GH Pages
2. build_wlma_binaries_ghh.yaml - bulding Windows, Linuex, macOS x86 and Android binaries, sigining Android with GPlay Key (from secrets)
3. build_macos_arm_sh.yaml - self hosted runner that builds Apple Silicon version for macOS
4. build_release_binaries.yaml - runs #2 and #3, collects the artefacts and produces a Release

All workflows relie on a few files that are missing and stored as zip/Base64 secret that are restored right after checkout.
