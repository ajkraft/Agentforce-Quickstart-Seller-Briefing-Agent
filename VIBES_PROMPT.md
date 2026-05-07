# Vibes prompt — Install the Seller Briefing Agent

Copy everything in the fenced block below and paste it into a new Agentforce Vibes chat.

**Before you paste:** in the Vibes chat panel, set **Auto-approve** to allow **Read (all), Edit (all), All Commands, MCP**. This lets Vibes install missing prerequisites and run CLI commands without stopping to ask you for permission on every single one.

The only step where Vibes will pause for you is the **browser-based Salesforce login** — that's a one-time click-through to log into your org. Everything else is automatic.

```
You are operating in Agentforce Vibes. Your job is to install the Seller Briefing Agent quickstart from the GitHub repository https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent into my currently authorized default Salesforce org.

I am not a developer. I may have never used a terminal or an IDE before. Execute all steps autonomously. Do not stop to ask me whether to install missing prerequisites — install them. Communicate in plain English as you go, one short status line per step. The only places you should pause and wait for me are the browser-based Salesforce login in Phase 2 and a final macOS admin password prompt if Homebrew is being installed for the very first time.

If a step fails with an error you can fix on your own, fix it and continue. Never ask me to run a shell command myself unless you have genuinely exhausted your options.

PHASE 1 - BOOTSTRAP PREREQUISITES (auto-install anything missing)

Detect tools using `command -v <tool>` (not `brew list ...`, since tools may be installed outside Homebrew, e.g. via nvm). For each tool below: if present, log "OK" and continue; if missing, install it and continue.

1. Detect platform with `uname -s`:
   - Darwin = macOS. Use Homebrew for installs.
   - Linux = Linux. Use the appropriate package manager (apt, dnf, etc.).
   - Anything else = halt with: "This installer supports macOS and Linux. On Windows, please use WSL."

2. Homebrew (macOS only): `command -v brew`. If missing, install with the official one-liner:
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   The first run may prompt me for my Mac admin password in the terminal. Tell me ONE short line: "Homebrew is installing - if you see a 'Password:' prompt, type your Mac login password (you won't see characters as you type, that's normal)." After Homebrew finishes, run `eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon) or `eval "$(/usr/local/bin/brew shellenv)"` (Intel) so brew is on PATH for the rest of this session.

3. Git: `command -v git`. If missing on macOS, run `xcode-select --install` (this opens a GUI dialog; tell me to click "Install" if I see it). On Linux, install via package manager.

4. Node.js: `command -v node`. If missing:
   - macOS: `brew install node`.
   - Linux (Debian/Ubuntu): `sudo apt-get update && sudo apt-get install -y nodejs npm`.

5. Salesforce CLI: `sf --version`. If the command fails OR returns a version older than 2.100, install/upgrade:
   - macOS: `brew install sf-cli` (or `brew upgrade sf-cli` if a stale version is present).
   - Linux: `npm install -g @salesforce/cli`.

PHASE 2 - AUTHORIZE A SALESFORCE ORG (one user click required)

6. Check for a default org: `sf org display --json`.
   - If it succeeds and returns a username, log "Already logged into <username>" and skip to Phase 3.

7. If no default org, ask me ONE question only: "Are you connecting to a Production org or a Sandbox?"
   - Production: run `sf org login web -a MyOrg`.
   - Sandbox: run `sf org login web -a MyOrg --instance-url https://test.salesforce.com`.
   This opens a browser window. Tell me: "A browser tab just opened. Log in with your Salesforce credentials. When you see a Salesforce page that says you can close the tab, come back here. I'll continue automatically." Wait for the command to finish.

8. Set it as default: `sf config set target-org=MyOrg`.

PHASE 3 - INSTALL THE AGENT (fully autonomous)

9. Clone the repo (if not already cloned in the current directory):
   `git clone https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent.git`
   then `cd Agentforce-Quickstart-Seller-Briefing-Agent`.

10. Deploy the source: `sf project deploy start`.
    FALLBACK: if the deploy fails because one of the standard managed actions referenced by the GenAiPlugin (EmployeeCopilot__*, SalesMgmt__*, runtime_sales_forecasting__*) doesn't exist in this org, recover automatically by regenerating the agent from the spec YAML:
    `sf agent create --spec specs/seller-briefing-agent.yaml --name "Seller Briefing Agent" --api-name Seller_Briefing_Agent`
    This LLM-generates topics from the spec and may take 30-60 seconds. Then continue to step 11.

11. Activate the agent: `sf agent activate --api-name Seller_Briefing_Agent --version 1`. If the response says it's already active, that's fine - keep going.

12. Assign the permission set to me: `sf org assign permset --name Seller_Briefing_Agent`. If already assigned, fine.

13. Smoke test: `sf data query --query "SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName = 'Seller_Briefing_Agent'"`. Confirm exactly one row returns. If zero, the agent didn't get created - surface the issue.

PHASE 4 - TELL ME HOW TO USE IT

14. End with EXACTLY this message in your final response:

"All set. Your Seller Briefing Agent is installed and active.

To test it:
1. Open your Salesforce org in a browser.
2. Navigate to any Lead, Opportunity, or Account record.
3. Click the Agentforce panel - the sparkle icon in the upper-right utility bar.
4. Ask: 'Brief me on this record.'

If the panel doesn't appear, refresh the page and confirm Agentforce is enabled in your org (Setup -> Einstein Setup)."

GUARDRAILS

- Do NOT modify any Salesforce configuration outside this repo's force-app/ directory.
- Do NOT install anything beyond the prerequisites listed in Phase 1 and the metadata in this repo.
- Do NOT change my default org once set in step 8.
- Do NOT ask me to run shell commands myself. Run them yourself.
- Keep your status messages short and human-readable. I'm not a developer.
```

---

## What this prompt does

| Phase | What | Who acts |
| --- | --- | --- |
| 1 — Bootstrap | Detect platform; auto-install Homebrew, Node, sf CLI, Git if missing | Vibes (you may type your Mac password once if Homebrew is installing for the first time) |
| 2 — Org login | Open Salesforce login in your browser | You click through the login once |
| 3 — Install | Clone repo, deploy metadata, activate agent, assign permission set | Vibes |
| 4 — Test | Tells you exactly how to test in your org | You |

If anything goes wrong mid-install (e.g. a missing managed action), the fallback uses `sf agent create --spec` to regenerate the agent from a YAML spec — no other action required from you.
