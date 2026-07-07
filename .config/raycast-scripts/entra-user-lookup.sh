#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Entra User Lookup
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon icons/entra.svg
# @raycast.packageName me.louisjannett.raycast.entra-user-lookup

# Documentation:
# @raycast.description Look up an Entra ID user via the GetCredentialType endpoint
# @raycast.author Louis Jannett

# @raycast.argument1 { "type": "text", "placeholder": "Username" }

set -euo pipefail

username="$1"

# Fail early with a clear message rather than a cryptic one mid-request.
for cmd in http jq; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

endpoint="https://login.microsoftonline.com/common/GetCredentialType?mkt=en-US"

# --ignore-stdin stops HTTPie from blocking on stdin; --body drops the response headers.
response=$(http --ignore-stdin --body POST "$endpoint" "username=$username") || {
    echo "Request to $endpoint failed" >&2
    exit 1
}

# A non-JSON body means an error page / rate-limit response — surface it instead of parsing blindly.
if ! jq -e . >/dev/null 2>&1 <<<"$response"; then
    echo "Unexpected (non-JSON) response:" >&2
    echo "$response" >&2
    exit 1
fi

exists=$(jq -r '.IfExistsResult // empty' <<<"$response")
throttled=$(jq -r '.ThrottleStatus // 0' <<<"$response")

# IfExistsResult codes returned by the endpoint.
case "$exists" in
    0 | 6) verdict="✅ User exists" ;;
    1)     verdict="❌ User not found" ;;
    5)     verdict="🔀 User exists in a different identity provider" ;;
    *)     verdict="❓ Unrecognized IfExistsResult: ${exists:-none}" ;;
esac

echo "$verdict"

# Tenants with enumeration protection return canned values, so the verdict can't be trusted.
if [[ "$throttled" != "0" ]]; then
    echo "⚠️  Enumeration protection is active — result may be unreliable."
fi

echo
jq <<<"$response"
