#!/bin/bash -eu
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

cd $SRC/superseedr

# The repository pins a stable toolchain; fuzzing needs the image's nightly.
rm -f rust-toolchain.toml

# The release profile enables LTO and strips symbols, which sanitizer builds do not want.
export CARGO_PROFILE_RELEASE_LTO=false
export CARGO_PROFILE_RELEASE_STRIP=none

if [ "$SANITIZER" = "coverage" ]; then
  cargo fuzz build -O
else
  cargo fuzz build -O --debug-assertions
fi

# Seed corpora for every target.
python3 scripts/fuzz_seed_corpus.py

# fuzz/ is a workspace member, so its binaries land in the workspace target directory.
FUZZ_OUT=target/x86_64-unknown-linux-gnu/release
for f in fuzz/fuzz_targets/*.rs; do
  FUZZ_TARGET=$(basename "${f%.*}")
  cp "$FUZZ_OUT/$FUZZ_TARGET" "$OUT/"
  if [ -f "fuzz/dictionaries/$FUZZ_TARGET.dict" ]; then
    cp "fuzz/dictionaries/$FUZZ_TARGET.dict" "$OUT/"
  fi
  if [ -d "fuzz/corpus/$FUZZ_TARGET" ]; then
    zip -jqr "$OUT/${FUZZ_TARGET}_seed_corpus.zip" "fuzz/corpus/$FUZZ_TARGET"
  fi
done
