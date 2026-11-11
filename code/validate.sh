#!/bin/bash
# Priority Follow-Through: read-only health check. Changes nothing in the org.
# Usage: ./validate.sh <org-alias> [seller-username]

set -uo pipefail
ORG="${1:-}"
SELLER="${2:-}"
if [ -z "$ORG" ]; then
    echo "Usage: ./validate.sh <org-alias> [seller-username]"
    exit 1
fi

count() {
    sf data query --target-org "$ORG" --json -q "$1" 2>/dev/null | grep -o '"totalSize": *[0-9]*' | grep -o '[0-9]*' | head -1
}
check() {
    # check <label> <actual> <expected-minimum>
    local mark="OK  "
    if [ -z "$2" ] || [ "$2" -lt "$3" ]; then mark="FAIL"; fi
    printf "  [%s] %-46s %s (want >= %s)\n" "$mark" "$1" "${2:-error}" "$3"
}

echo "Priority Follow-Through: health check for $ORG"
echo ""
echo "Metadata"
check "Apex classes (2 + 2 tests)" "$(count "SELECT Id FROM ApexClass WHERE Name IN ('AccountPriorityService','AccountPriorityServiceTest','PriorityActionService','PriorityActionServiceTest')")" 4
check "Permission sets (Admin, Agent User)" "$(count "SELECT Id FROM PermissionSet WHERE Name IN ('Priority_Admin','Priority_Agent_User')")" 2
check "Standard price book active" "$(count "SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true")" 1

echo ""
echo "Data"
check "DEMO accounts" "$(count "SELECT Id FROM Account WHERE Name LIKE 'DEMO %'")" 50
# Minimums hold whether or not the Account Brief demo created the 5 test accounts first.
check "DEMO contacts" "$(count "SELECT Id FROM Contact WHERE Account.Name LIKE 'DEMO %'")" 160
check "DEMO opportunities" "$(count "SELECT Id FROM Opportunity WHERE Account.Name LIKE 'DEMO %'")" 200
check "DEMO orders" "$(count "SELECT Id FROM Order WHERE Account.Name LIKE 'DEMO %'")" 490
check "Open DEMO priorities" "$(count "SELECT Id FROM Account_Priority__c WHERE Account__r.Name LIKE 'DEMO %' AND Status__c = 'Open'")" 57
check "Actioned or Dismissed (history)" "$(count "SELECT Id FROM Account_Priority__c WHERE Account__r.Name LIKE 'DEMO %' AND Status__c != 'Open'")" 21

echo ""
echo "Test accounts (exact)"
for row in "Lakeshore Medical Group|Chicago|3" "Pinecrest School District|Portland|1" "Harbor Supply Co|Seattle|1" "Harbor Supply Co|Tacoma|1" "Ridgeway Logistics|Dallas|0"; do
    IFS='|' read -r name city want <<< "$row"
    got=$(count "SELECT Id FROM Account_Priority__c WHERE Account__r.Name = 'DEMO $name' AND Account__r.BillingCity = '$city' AND Status__c = 'Open'")
    mark="OK  "; [ "$got" = "$want" ] || mark="FAIL"
    printf "  [%s] %-46s %s (want %s)\n" "$mark" "DEMO $name ($city) open priorities" "$got" "$want"
done

if [ -n "$SELLER" ]; then
    echo ""
    echo "Test seller: $SELLER"
    check "Accounts owned (seller book)" "$(count "SELECT Id FROM Account WHERE Name LIKE 'DEMO %' AND Owner.Username = '$SELLER'")" 20
    check "Priority_Agent_User assigned" "$(count "SELECT Id FROM PermissionSetAssignment WHERE Assignee.Username = '$SELLER' AND PermissionSet.Name = 'Priority_Agent_User'")" 1
    check "Priority_Agent_Access assigned" "$(count "SELECT Id FROM PermissionSetAssignment WHERE Assignee.Username = '$SELLER' AND PermissionSet.Name = 'Priority_Agent_Access'")" 1
fi

echo ""
echo "Agent"
sf data query --target-org "$ORG" --json -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = 'Priority_Followthrough' ORDER BY VersionNumber DESC" 2>/dev/null \
    | grep -o '"VersionNumber": *[0-9]*\|"Status": *"[A-Za-z]*"' | paste - - | sed 's/^/  /' \
    || echo "  Not published yet (draft only)."
