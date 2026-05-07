# Vibes prompt — Install the Seller Briefing Agent

Copy everything in the fenced block below and paste it into a new Agentforce Vibes chat.

**Before you paste:** in the Vibes chat panel, set **Auto-approve** to allow **Read (all), Edit (all), All Commands, MCP**. This lets Vibes install missing prerequisites and run CLI commands without stopping to ask you for permission on every single one.

The only step where Vibes will pause for you is the **browser-based Salesforce login** — that's a one-time click-through to log into your org. Everything else is automatic.

```
You are operating in Agentforce Vibes. Your job is to install the Seller Briefing Agent quickstart from the GitHub repository https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent into my currently authorized default Salesforce org.

This quickstart installs an INTERNAL (Employee) Agentforce agent — the kind that runs in the Lightning utility bar on Lead, Opportunity, and Account record pages. The agent is defined by a hand-authored Agent Script at force-app/main/default/aiAuthoringBundles/Seller_Briefing_Agent/Seller_Briefing_Agent.agent which explicitly sets `agent_type: "AgentforceEmployeeAgent"`. Do NOT use `sf agent create --spec` or `sf agent generate authoring-bundle --spec` — those commands ignore the internal-agent intent and produce a Service Agent. Use `sf agent publish authoring-bundle` only.

IMPORTANT: Trust the actual repo contents on disk after you clone, NOT any prior knowledge you may have of the repo's structure. The repo was recently restructured: it used to ship pre-built Bot/BotVersion/GenAiPlannerBundle/GenAiPlugin XML files, but those have been removed. The repo now ships only an `aiAuthoringBundles/` directory and a `permissionsets/` directory under `force-app/main/default/`. If you find yourself thinking "this repo has a bots folder," you are wrong — re-read the disk.

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

9. Get a FRESH clone of the repo. ALWAYS do a clean clone — do not reuse a clone from a prior install attempt, because the repo structure has changed (it used to ship pre-built Bot/GenAiPlannerBundle/GenAiPlugin metadata; it now ships an Agent Script bundle instead).
   - If a directory `Agentforce-Quickstart-Seller-Briefing-Agent` already exists in the current working directory, delete it: `rm -rf Agentforce-Quickstart-Seller-Briefing-Agent`.
   - Then clone fresh: `git clone https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent.git`
   - Then `cd Agentforce-Quickstart-Seller-Briefing-Agent`.

9a. VERIFY the expected files are present before proceeding. Run `ls force-app/main/default/aiAuthoringBundles/Seller_Briefing_Agent/`. You MUST see exactly two files:
    - `Seller_Briefing_Agent.agent`
    - `Seller_Briefing_Agent.bundle-meta.xml`
    Also run `ls force-app/main/default/` and confirm you see ONLY two directories: `aiAuthoringBundles` and `permissionsets`. If you see `bots`, `genAiPlannerBundles`, or `genAiPlugins` directories, you are looking at a stale cached clone — the current repo does NOT contain those. In that case, halt and surface the issue to me.

10. PRE-CHECK: see if a previous broken install of this agent exists:
    `sf data query --query "SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName = 'Seller_Briefing_Agent'"`
    If exactly one row returns, tell me: "I see a previous Seller Briefing Agent in this org. I need to delete it before re-installing because earlier revisions of this quickstart created it as a Service Agent. I'll handle the delete automatically." Then attempt to delete it via the Tooling API:
    `sf data delete record --sobject BotDefinition --record-id <Id from query> --use-tooling-api`
    If the delete fails, surface the error and tell me to manually delete the agent under Setup -> Agentforce Agents -> Seller Briefing Agent -> Delete, then say "Tell me 'continue' once you've deleted it" and wait. Otherwise continue.

11. Validate the Agent Script compiles:
    `sf agent validate authoring-bundle --api-name Seller_Briefing_Agent`

12. Publish the authoring bundle. THIS IS THE ONLY COMMAND THAT CREATES THE AGENT. Do not use `sf agent create` or `sf project deploy` for the bundle:
    `sf agent publish authoring-bundle --api-name Seller_Briefing_Agent --skip-retrieve`
    This compiles the .agent script, creates the Bot/BotVersion/GenAiPlannerBundle/GenAiPlugin in my org as an INTERNAL/Employee Agentforce agent (because the .agent script declares `agent_type: "AgentforceEmployeeAgent"`), and deploys the AiAuthoringBundle metadata. It takes 30-60 seconds.

13. Deploy the permission set on top:
    `sf project deploy start --metadata "PermissionSet:Seller_Briefing_Agent"`

14. Activate the agent: `sf agent activate --api-name Seller_Briefing_Agent --version 1`. If the response says it's already active, that's fine - keep going.

15. Assign the permission set to me: `sf org assign permset --name Seller_Briefing_Agent`. If already assigned, fine.

16. Smoke test: `sf data query --query "SELECT Id, DeveloperName, Type FROM BotDefinition WHERE DeveloperName = 'Seller_Briefing_Agent'"`. Confirm exactly one row returns AND the Type field is 'InternalCopilot' (this is the runtime value that corresponds to `agent_type: "AgentforceEmployeeAgent"` in the Agent Script). If Type comes back as 'ExternalCopilot' or any other value, surface it - that means the publish step somehow produced the wrong type and we need to investigate.

PHASE 4 - TELL ME HOW TO USE IT

17. End with EXACTLY this message in your final response:

"All set. Your Seller Briefing Agent is installed and active.

To test it:
1. Open your Salesforce org in a browser.
2. Navigate to any Lead, Opportunity, or Account record.
3. Click the Agentforce panel - the sparkle icon in the upper-right utility bar.
4. Ask: 'Brief me on this record.'

If the panel doesn't appear, refresh the page and confirm Agentforce is enabled in your org (Setup -> Einstein Setup)."

GUARDRAILS

- Do NOT modify any Salesforce configuration outside this repo's force-app/ directory and the agent we're creating.
- Do NOT install anything beyond the prerequisites listed in Phase 1.
- Do NOT change my default org once set in step 8.
- Do NOT ask me to run shell commands myself. Run them yourself.
- Do NOT use `sf agent create --spec` or `sf agent generate authoring-bundle --spec` - those commands have a known bug where they produce a Service Agent regardless of the spec's `agentType: internal` value.
- Keep your status messages short and human-readable. I'm not a developer.
```

---

## What this prompt does

| Phase | What | Who acts |
| --- | --- | --- |
| 1 — Bootstrap | Detect platform; auto-install Homebrew, Node, sf CLI, Git if missing | Vibes (you may type your Mac password once if Homebrew is installing for the first time) |
| 2 — Org login | Open Salesforce login in your browser | You click through the login once |
| 3 — Install | Detect/clean up prior broken install; validate Agent Script; publish authoring bundle (creates internal/employee agent); deploy permset; activate; assign; smoke-test the type | Vibes |
| 4 — Test | Tells you exactly how to test in your org | You |

The agent is created from a **hand-authored Agent Script** (`.agent` file) that explicitly declares `agent_type: "AgentforceEmployeeAgent"`. That's the only reliable way to produce an internal employee agent today — both `sf agent create --spec` and `sf agent generate authoring-bundle --spec` have a known issue where they ignore the spec's `agentType: internal` and produce a Service Agent.
