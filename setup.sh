#!/usr/bin/env bash
#
# Seller Briefing Agent quickstart installer.
#
# Usage:
#   ./setup.sh                  # uses your default Salesforce org
#   ./setup.sh MyOrgAlias       # targets a specific authorized org alias
#
# Prerequisites:
#   - Salesforce CLI installed (sf), version 2.100 or newer
#   - An authorized org (sf org login web -a MyOrgAlias)
#   - Agentforce enabled in the target org
#
# This installer creates an INTERNAL (Employee) Agentforce agent named
# "Seller Briefing Agent" using the spec at specs/seller-briefing-agent.yaml.
# The Bot, BotVersion, GenAiPlannerBundle, and GenAiPlugin metadata are
# generated fresh in the target org by `sf agent create`, which adapts to
# whatever standard managed actions are available in that org.

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

echo "==> Step 1/4: Generating the agent in the org from specs/seller-briefing-agent.yaml"
echo "    (This LLM-generates an internal/employee Agentforce agent; takes 30-60 seconds.)"
if ! sf agent create \
    --spec specs/seller-briefing-agent.yaml \
    --name "Seller Briefing Agent" \
    --api-name Seller_Briefing_Agent \
    "${TARGET_ARGS[@]}"; then
  echo
  echo "==> 'sf agent create' failed. If the agent already exists in this org from a prior install, delete it first:"
  echo "      Setup -> Agentforce Agents -> Seller Briefing Agent -> Delete"
  echo "    then re-run this script."
  exit 1
fi

echo
echo "==> Step 2/4: Deploying the permission set"
sf project deploy start "${TARGET_ARGS[@]}"

echo
echo "==> Step 3/4: Activating Seller_Briefing_Agent v1"
sf agent activate \
  --api-name Seller_Briefing_Agent \
  --version 1 \
  "${TARGET_ARGS[@]}" || echo "(activation reported an error; continuing in case the agent is already active)"

echo
echo "==> Step 4/4: Assigning Seller_Briefing_Agent permission set to the running user"
sf org assign permset \
  --name Seller_Briefing_Agent \
  "${TARGET_ARGS[@]}" || echo "(permset assign reported an error; continuing in case it was already assigned)"

echo
echo "==> Done."
echo
echo "Test it: open any Lead, Opportunity, or Account record in Lightning, click the"
echo "Agentforce panel (sparkle icon in the upper-right utility bar), and ask:"
echo "    \"Brief me on this record.\""
