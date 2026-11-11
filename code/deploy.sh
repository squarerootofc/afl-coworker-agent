#!/bin/bash
# Priority Follow-Through: pre-tested fallback deploy.
#
# Deploys the priority object and fields, the two Apex actions and their tests, the permission set,
# the 50-account seed, and the agent. Standalone: does not need afl-coworker-skills.
#
# Usage:   ./deploy.sh <org-alias> [seller-username]
# Example: ./deploy.sh my-sandbox seller@example.com
#
# When both demos share an org, run afl-coworker-skills/code/deploy.sh FIRST. Its seed deletes
# every DEMO account, which fails once account priorities exist (Restrict lookup).
#
# Nothing here deletes data. Re-running is safe: every step is add-only or idempotent.
# To top up open priorities between rehearsals, run only:  ./deploy.sh <org-alias> --top-up

set -euo pipefail
cd "$(dirname "$0")"

ORG="${1:-}"
SELLER="${2:-}"
if [ -z "$ORG" ]; then
    echo "Usage: ./deploy.sh <org-alias> [seller-username | --top-up]"
    exit 1
fi

run_apex() {
    # Writes a temp copy of a seed script with the seller username filled in, then runs it.
    local file="$1"
    local tmp
    tmp="$(mktemp -t priority-seed).apex"
    if [ -n "$SELLER" ] && [ "$SELLER" != "--top-up" ]; then
        sed "s|^String SELLER_USERNAME = '';|String SELLER_USERNAME = '${SELLER}';|" "$file" > "$tmp"
    else
        cp "$file" "$tmp"
    fi
    echo "  -> $file"
    sf apex run --target-org "$ORG" --file "$tmp" --json > "$tmp.out" || true
    if ! grep -q '"success": true' "$tmp.out"; then
        echo "     FAILED. Output:"
        cat "$tmp.out"
        exit 1
    fi
    grep -o 'SEED 0[1-4] COMPLETE[^"]*\|[A-Za-z ]* added: [^"\\]*\|Open DEMO priorities now: [0-9]*\|DEMO accounts now: [0-9]*\|CPU ms used: [^"\\]*' "$tmp.out" | sed 's/^/     /' || true
    rm -f "$tmp" "$tmp.out"
}

echo "=========================================="
echo "Priority Follow-Through: deploy to $ORG"
echo "=========================================="

echo "Step 1: Checking the org connection..."
sf org display --target-org "$ORG" --json > /dev/null
IS_PROD=$(sf data query --target-org "$ORG" --json -q "SELECT IsSandbox, OrganizationType FROM Organization" \
    | grep -o '"IsSandbox": *[a-z]*\|"OrganizationType": *"[^"]*"' | tr '\n' ' ')
echo "  $IS_PROD"
if echo "$IS_PROD" | grep -q '"IsSandbox": *false' && ! echo "$IS_PROD" | grep -q 'Developer Edition'; then
    read -r -p "  This org is not a sandbox or Developer Edition. Continue anyway? (yes/no) " ok
    [ "$ok" = "yes" ] || exit 1
fi

if [ "$SELLER" = "--top-up" ]; then
    echo "Top-up only: adding Open priorities to accounts below their baseline count..."
    run_apex scripts/apex/seed-04-priorities.apex
    exit 0
fi

echo "Step 2: Deploying the priority object and fields..."
sf project deploy start --target-org "$ORG" --metadata CustomObject:Account_Priority__c --wait 10

echo "Step 3: Giving you (the driver) field access, so tests and seeds can run..."
# New fields get no field-level security. Anonymous Apex and WITH USER_MODE both enforce it.
sf project deploy start --target-org "$ORG" --metadata PermissionSet:Priority_Admin --wait 10
sf org assign permset --target-org "$ORG" --name Priority_Admin || true

echo "Step 4: Deploying the Apex actions and running their tests..."
sf project deploy start --target-org "$ORG" \
    --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest \
               ApexClass:PriorityActionService ApexClass:PriorityActionServiceTest \
    --test-level RunSpecifiedTests --tests AccountPriorityServiceTest PriorityActionServiceTest --wait 15

echo "Step 5: Deploying the seller permission set (needs the classes from step 4)..."
sf project deploy start --target-org "$ORG" --metadata PermissionSet:Priority_Agent_User --wait 10
if [ -n "$SELLER" ]; then
    sf org assign permset --target-org "$ORG" --name Priority_Agent_User --on-behalf-of "$SELLER" || true
fi

echo "Step 6: Seeding the 50-account book (add-only)..."
run_apex scripts/apex/seed-01-accounts.apex
run_apex scripts/apex/seed-02-activity.apex
run_apex scripts/apex/seed-03-orders.apex
run_apex scripts/apex/seed-04-priorities.apex

echo "Step 7: Validating and deploying the agent authoring bundle..."
sf agent validate authoring-bundle --json --target-org "$ORG" --api-name Priority_Followthrough
sf project deploy start --target-org "$ORG" --metadata AiAuthoringBundle:Priority_Followthrough --wait 10

echo ""
echo "=========================================="
echo "Deployed. The agent is a DRAFT: not published, not active."
echo "=========================================="
echo "Next (runbook page 11):"
echo "  1. Preview:   sf agent preview start --json --target-org $ORG --use-live-actions --authoring-bundle Priority_Followthrough"
echo "  2. Publish:   sf agent publish authoring-bundle --json --target-org $ORG --api-name Priority_Followthrough"
echo "  3. Activate:  sf agent activate --json --target-org $ORG --api-name Priority_Followthrough"
echo "  4. Access:    sf project deploy start --target-org $ORG --metadata PermissionSet:Priority_Agent_Access"
echo "                sf org assign permset --target-org $ORG --name Priority_Agent_Access [--on-behalf-of <seller>]"
