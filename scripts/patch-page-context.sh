#!/usr/bin/env bash
#
# patch-page-context.sh
#
# Wires the Seller Briefing Agent up to Lightning page context so it can
# auto-detect the record on screen (no "Set Context" needed).
#
# WHY THIS EXISTS:
# The Agent Script DSL (`.agent` files) used by the new Advanced Builder does
# not currently expose a way to mark a variable as "External / page-context-
# bound". Variables declared in the .agent file are emitted into the deployed
# BotVersion XML with `<visibility>Internal</visibility>` and
# `<includeInPrompt>false</includeInPrompt>`. Internal variables are NOT
# populated by the Lightning runtime when the agent panel opens on a record
# page, so `currentRecordId` and `currentObjectApiName` stay empty and the
# agent can't answer "Brief me on this account."
#
# Working employee agents (e.g. Salesforce's reference Account_Health_Agent)
# declare the same two variables with `<visibility>External</visibility>` and
# `<includeInPrompt>true</includeInPrompt>`. That is the mechanism the
# Lightning runtime looks for to inject the page's record ID and sObject API
# name into the conversation.
#
# This script bridges that gap. After every `sf agent publish authoring-
# bundle`, it:
#   1. Finds the highest BotVersion number for Seller_Briefing_Agent.
#   2. Retrieves the deployed BotVersion XML.
#   3. Flips currentRecordId and currentObjectApiName from
#      Internal/false -> External/true.
#   4. Deactivates the BotVersion (active versions are immutable).
#   5. Redeploys the patched XML.
#   6. Reactivates the BotVersion.
#
# Usage:
#   ./scripts/patch-page-context.sh                 # uses default org
#   ./scripts/patch-page-context.sh MyOrgAlias      # targets a specific org
#
# Idempotent: re-running on already-External variables is a no-op.

set -euo pipefail

ORG="${1:-}"
TARGET_ARGS=()
if [[ -n "$ORG" ]]; then
  TARGET_ARGS+=(--target-org "$ORG")
  ORG_LABEL="$ORG"
else
  ORG_LABEL="default org"
fi

API_NAME="Seller_Briefing_Agent"

echo "==> Patching $API_NAME for Lightning page-context binding ($ORG_LABEL)"

LATEST_VERSION=$(sf data query \
  --query "SELECT VersionNumber FROM BotVersion WHERE BotDefinition.DeveloperName = '${API_NAME}' ORDER BY VersionNumber DESC LIMIT 1" \
  --json \
  "${TARGET_ARGS[@]}" 2>/dev/null \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['records'][0]['VersionNumber'])" 2>/dev/null || echo "")

if [[ -z "$LATEST_VERSION" ]]; then
  echo "ERROR: Could not find any BotVersion for ${API_NAME}. Did you publish first?" >&2
  exit 1
fi
echo "    Latest BotVersion: v${LATEST_VERSION}"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"
mkdir -p force-app/main/default
cat > sfdx-project.json <<'EOF'
{"packageDirectories":[{"path":"force-app","default":true}],"namespace":"","sfdcLoginUrl":"https://login.salesforce.com","sourceApiVersion":"63.0"}
EOF

echo "    Retrieving deployed BotVersion XML..."
sf project retrieve start \
  --metadata "Bot:${API_NAME}" \
  "${TARGET_ARGS[@]}" >/dev/null

BOT_VERSION_XML="force-app/main/default/bots/${API_NAME}/v${LATEST_VERSION}.botVersion-meta.xml"
if [[ ! -f "$BOT_VERSION_XML" ]]; then
  echo "ERROR: Expected file not found after retrieve: $BOT_VERSION_XML" >&2
  exit 1
fi

ALREADY_PATCHED=$(python3 - "$BOT_VERSION_XML" <<'PYEOF'
import sys, xml.etree.ElementTree as ET
path = sys.argv[1]
ns = "http://soap.sforce.com/2006/04/metadata"
tree = ET.parse(path)
root = tree.getroot()
needs = False
for cv in root.findall(f"{{{ns}}}conversationVariables"):
    devname = cv.find(f"{{{ns}}}developerName")
    if devname is None or devname.text not in ("currentRecordId", "currentObjectApiName"):
        continue
    vis = cv.find(f"{{{ns}}}visibility")
    prompt = cv.find(f"{{{ns}}}includeInPrompt")
    if (vis is not None and vis.text != "External") or (prompt is not None and prompt.text != "true"):
        needs = True
print("yes" if not needs else "no")
PYEOF
)

if [[ "$ALREADY_PATCHED" == "yes" ]]; then
  echo "    Already External/includeInPrompt=true. Nothing to do."
  exit 0
fi

echo "    Flipping currentRecordId & currentObjectApiName to External/includeInPrompt=true..."
python3 - "$BOT_VERSION_XML" <<'PYEOF'
import sys, xml.etree.ElementTree as ET
path = sys.argv[1]
ns = "http://soap.sforce.com/2006/04/metadata"
ET.register_namespace("", ns)

DESCRIPTIONS = {
    "currentRecordId": (
        "The ID of the record on the user's screen. It may not relate to "
        "the user's input. Only use this if the user input mentions 'this', "
        "'current', 'the record', etc. If in doubt, don't use it."
    ),
    "currentObjectApiName": (
        "The API name of the Salesforce object (such as Account, Lead, or "
        "Opportunity) associated with the record the user is viewing. Do "
        "not use this if the user is already talking about a different "
        "object in the conversation."
    ),
}

tree = ET.parse(path)
root = tree.getroot()
for cv in root.findall(f"{{{ns}}}conversationVariables"):
    devname = cv.find(f"{{{ns}}}developerName")
    if devname is None or devname.text not in DESCRIPTIONS:
        continue
    vis = cv.find(f"{{{ns}}}visibility")
    if vis is not None:
        vis.text = "External"
    prompt = cv.find(f"{{{ns}}}includeInPrompt")
    if prompt is not None:
        prompt.text = "true"
    desc = cv.find(f"{{{ns}}}description")
    if desc is not None:
        desc.text = DESCRIPTIONS[devname.text]

tree.write(path, xml_declaration=True, encoding="UTF-8")
PYEOF

echo "    Deactivating v${LATEST_VERSION} (active versions are immutable)..."
sf agent deactivate --api-name "$API_NAME" "${TARGET_ARGS[@]}" >/dev/null

echo "    Deploying patched BotVersion..."
sf project deploy start \
  --metadata "Bot:${API_NAME}" \
  "${TARGET_ARGS[@]}" >/dev/null

echo "    Reactivating v${LATEST_VERSION}..."
sf agent activate \
  --api-name "$API_NAME" \
  --version "$LATEST_VERSION" \
  "${TARGET_ARGS[@]}" >/dev/null

echo "==> Page-context binding wired up. The agent will now read the record"
echo "    on screen automatically when opened from a Lightning record page."
