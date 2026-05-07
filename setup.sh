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
# This installer publishes a hand-authored Agent Script (Agent Script DSL)
# that creates an INTERNAL Agentforce employee agent (the kind that runs in
# the Lightning utility bar on Lead, Opportunity, and Account record pages).
# The Agent Script lives at
#   force-app/main/default/aiAuthoringBundles/Seller_Briefing_Agent/Seller_Briefing_Agent.agent
# and explicitly sets `agent_type: "AgentforceEmployeeAgent"`. That value is
# what makes the resulting Bot an employee agent rather than a service agent.
# Neither `sf agent create --spec` nor `sf agent generate authoring-bundle
# --spec` honors `agentType: internal` in YAML specs today, so we don't use
# them.

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

echo "==> Step 1/4: Validating the Agent Script compiles"
sf agent validate authoring-bundle \
  --api-name Seller_Briefing_Agent \
  "${TARGET_ARGS[@]}"

echo
echo "==> Step 2/4: Publishing the authoring bundle to the org"
echo "    (Creates Bot, BotVersion, GenAiPlannerBundle, GenAiPlugin as an INTERNAL employee agent.)"
sf agent publish authoring-bundle \
  --api-name Seller_Briefing_Agent \
  --skip-retrieve \
  "${TARGET_ARGS[@]}"

echo
echo "==> Step 3/4: Deploying the permission set"
sf project deploy start \
  --metadata "PermissionSet:Seller_Briefing_Agent" \
  "${TARGET_ARGS[@]}"

echo
echo "==> Step 4/4: Activating the latest BotVersion and assigning the permission set"
LATEST_VERSION=$(sf data query \
  --query "SELECT VersionNumber FROM BotVersion WHERE BotDefinition.DeveloperName = 'Seller_Briefing_Agent' ORDER BY VersionNumber DESC LIMIT 1" \
  --json \
  "${TARGET_ARGS[@]}" 2>/dev/null \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['records'][0]['VersionNumber'])" 2>/dev/null)

if [[ -z "$LATEST_VERSION" ]]; then
  LATEST_VERSION=1
  echo "(could not determine latest BotVersion; defaulting to v1)"
else
  echo "Latest BotVersion: v${LATEST_VERSION}"
fi

sf agent activate \
  --api-name Seller_Briefing_Agent \
  --version "$LATEST_VERSION" \
  "${TARGET_ARGS[@]}" || echo "(activation reported an error; continuing in case the agent is already active)"

sf org assign permset \
  --name Seller_Briefing_Agent \
  "${TARGET_ARGS[@]}" || echo "(permset assign reported an error; continuing in case it was already assigned)"

echo
echo "==> Done."
echo
echo "Test it: open any Lead, Opportunity, or Account record in Lightning, click the"
echo "Agentforce panel (sparkle icon in the upper-right utility bar), and ask:"
echo "    \"Brief me on this record.\""
