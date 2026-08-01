#!/bin/sh

set -eu

# Development-only identifier. Replacing it with the permanent Bundle ID is a
# hard gate before the first App Store Release build.
development_bundle_id="com.qoder.foursquare"

if [ "${CONFIGURATION:-}" = "Release" ] && \
   [ "${PRODUCT_BUNDLE_IDENTIFIER:-}" = "$development_bundle_id" ]; then
  echo "error: Release PRODUCT_BUNDLE_IDENTIFIER is still the development placeholder: $development_bundle_id" >&2
  exit 1
fi
