# A Linux renderer that matches `ci.yml`'s `goldens (linux)` job, for
# regenerating goldens from a Windows or macOS checkout.
#
# **Why this file exists.** Goldens have exactly one authoring platform and
# since M100.24 it is Linux (`dart_test.yaml` carries the reasoning). A Windows
# checkout that runs `--update-goldens` writes PNGs CI rejects, and it does it
# silently — the local run reports every test passing, because a platform always
# agrees with itself. Until M100.30 the only documented answers were "use WSL"
# or "let a cloud session do it"; this is the third, and it is reproducible.
#
# **The base is Ubuntu plus the official SDK tarball, not a vendor image.** The
# CI job is `runs-on: ubuntu-latest` with `subosito/flutter-action` reading
# `.fvmrc`, and that action downloads exactly this archive. A vendor image is a
# different font stack and a different libc, which is another way of saying a
# different rasteriser — and the whole contract of a golden is that one platform
# wrote it.
#
# **Validate before trusting it.** Run the golden suite on unmodified `main`
# content first; it must be green. A container that disagrees with the committed
# PNGs will not agree with CI either, and regenerating from it would replace 300
# correct pictures with 300 wrong ones.
#
#   docker build -f .claude/skills/flutter-testing/scripts/golden.Dockerfile \
#     -t memox-golden:3.44.8 .claude/skills/flutter-testing/scripts
#
#   # 1. validate — must print "All tests passed!"
#   git worktree add /tmp/mainref origin/main
#   docker run --rm -v /tmp/mainref:/src memox-golden:3.44.8 bash -lc '
#     cp -a /src /w2 && cd /w2 && flutter pub get &&
#     dart run build_runner build --delete-conflicting-outputs &&
#     TZ=UTC flutter test --tags golden'
#
#   # 2. regenerate — writes back into the mounted checkout
#   docker run --rm -v "$PWD":/w memox-golden:3.44.8 bash -lc '
#     flutter pub get &&
#     dart run build_runner build --delete-conflicting-outputs &&
#     TZ=UTC flutter test --tags golden --update-goldens'
#
# `TZ=UTC` is not optional: `card_detail` renders review timestamps through
# `toLocal()`, so without it the PNGs carry the machine's timezone. The image
# sets it as a default, and the command restates it so a reader of either does
# not have to check the other.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl xz-utils git unzip zip ca-certificates \
      libglu1-mesa python3 \
    && rm -rf /var/lib/apt/lists/*

# Keep in step with `.fvmrc`, which is what the CI job reads.
ARG FLUTTER_VERSION=3.44.8
RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz

ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV TZ=UTC

RUN git config --global --add safe.directory /opt/flutter \
    && git config --global --add safe.directory '*' \
    && flutter --version \
    && flutter precache --force --universal

# `prepare_test_fonts.sh`, baked in. Flutter's Linux test runner asks for
# lowercase material-font paths while the SDK artifact ships mixed case; without
# the symlinks every glyph falls back to the box font and all 300 goldens
# disagree at once. The CI job runs the script as a step; doing it here means
# every container run starts from the font state that step produces.
RUN cd "$FLUTTER_ROOT/bin/cache/artifacts/material_fonts" \
    && for f in *; do \
         l="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"; \
         [ "$f" = "$l" ] && continue; \
         [ -e "$l" ] && continue; \
         ln -s "$f" "$l"; \
       done \
    && test -f "$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/roboto-regular.ttf"

WORKDIR /w
