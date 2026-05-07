#!/usr/bin/env bash
#
# Seller Briefing Agent quickstart installer.
#
# Usage:
#   ./setup.sh                  # uses your default Salesforce org
#   ./setup.sh MyOrgAlias       # targets a specific authorized org alias
#
# Prerequisites:
#   - Salesforce CLI installed (sf)
#   - An authorized org (sf org login web -a MyOrgAlias)
#   - Agentforce enabled in the target org

set -euo pipefail

ORG="${1:-}"
TARGET_ARGS=()
if [[ -n "$ORG" ]]; then
  TARGET_ARGS+=(--target-org "$ORG")
  ORG_LABEL="$ORG"
else
  ORG_LABEL="default org"
fi

echo "==> Installing Seller Briefing Agent into $ORG_LABEL"
echo

echo "==> Step 1/3: Deploying source metadata"
if ! sf project deploy start "${TARGET_ARGS[@]}"; then
  echo
  echo "Direct metadata deploy failed. This usually means the target org is missing one of the standard managed actions referenced by the GenAiPlugin (EmployeeCopilot__*, SalesMgmt__*, runtime_sales_forecasting__*)."
  echo "Falling back: rebuilding the agent from the spec YAML via 'sf agent create'."
  echo
  sf agent create \
    --spec specs/seller-briefing-agent.yaml \
    --name "Seller Briefing Agent" \
    --api-name Seller_Briefing_Agent \
    "${TARGET_ARGS[@]}"
fi

echo
echo "==> Step 2/3: Activating Seller_Briefing_Agent v1"
sf agent activate \
  --api-name Seller_Briefing_Agent \
  --version 1 \
  "${TARGET_ARGS[@]}" || echo "(activation reported an error; continuing in case the agent is already active)"

echo
echo "==> Step 3/3: Assigning Seller_Briefing_Agent permission set to the running user"
sf org assign permset \
  --name Seller_Briefing_Agent \
  "${TARGET_ARGS[@]}" || echo "(permset assign reported an error; continuing in case it was already assigned)"

echo
echo "==> Done."
echo
echo "Test it: open any Lead, Opportunity, or Account record in Lightning, click the"
echo "Agentforce panel (sparkle icon in the upper-right utility bar), and ask:"
echo "    \"Brief me on this record.\""
