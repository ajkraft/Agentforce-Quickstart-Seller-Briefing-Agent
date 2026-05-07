# Vibes prompt — Install the Seller Briefing Agent

Copy everything in the fenced block below and paste it into a new Agentforce Vibes chat. Vibes will handle the rest end-to-end. You don't need to run any commands yourself.

```
You are operating in Agentforce Vibes. Your job is to install the Seller Briefing Agent quickstart from the GitHub repository https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent into my currently authorized default Salesforce org. Run the steps below end-to-end without asking me to run individual commands. If a step fails with an error you can fix on your own (e.g. a default org isn't set, a permset is already assigned, an agent is already activated), fix it and continue. If you hit something you genuinely cannot resolve, stop and tell me the exact error and what I need to do.

PRECONDITIONS — verify these first

1. A default Salesforce org is authorized. Run: `sf org display --json`. If no default org is set, halt and tell me to run `sf org login web -a MyOrg && sf config set target-org=MyOrg`, then come back and rerun this prompt.
2. Agentforce must be enabled in the target org. If a later step fails with an error indicating Agentforce or Einstein 1 Platform is disabled, halt and tell me to enable it in Setup -> Einstein Setup before retrying.

INSTALL STEPS — execute in order

1. Clone the repo into the current working directory if it isn't already cloned: `git clone https://github.com/ajkraft/Agentforce-Quickstart-Seller-Briefing-Agent.git`. `cd` into it.

2. Deploy the Salesforce DX source to my default org: `sf project deploy start`. This deploys the Bot, BotVersion, GenAiPlannerBundle, GenAiPlugin, and PermissionSet in one shot.

   FALLBACK: if this deploy fails because one of the standard managed actions referenced by the GenAiPlugin (`EmployeeCopilot__*`, `SalesMgmt__*`, `runtime_sales_forecasting__*`) doesn't exist in the target org, recover by regenerating the agent from the spec YAML instead:
   `sf agent create --spec specs/seller-briefing-agent.yaml --name "Seller Briefing Agent" --api-name Seller_Briefing_Agent`
   This LLM-generates topics from the spec and may take 30-60 seconds. Then continue to step 3.

3. Activate the agent: `sf agent activate --api-name Seller_Briefing_Agent --version 1`. If the agent is already active, that's fine — keep going.

4. Assign the permission set to the running user: `sf org assign permset --name Seller_Briefing_Agent`. If it's already assigned, that's fine — keep going.

5. Smoke test the install: `sf data query --query "SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName = 'Seller_Briefing_Agent'"`. Confirm exactly one row returns. If zero rows, the agent didn't get created — surface the issue.

6. Tell me exactly how to test it in plain language: "Open any Lead, Opportunity, or Account record in Lightning, click the Agentforce panel (the sparkle icon in the upper-right utility bar), and ask: 'Brief me on this record.'"

DO NOT

- Do not modify any other Salesforce configuration in my org beyond what's in this repo's force-app/ directory.
- Do not install any additional packages.
- Do not change my default org.

When all steps succeed, end with a one-line success summary that includes the agent API name, the org username it was installed into, and the test instruction.
```

---

## What this prompt does

| Step | Command | Purpose |
| --- | --- | --- |
| Verify | `sf org display --json` | Confirm a default org is set |
| Deploy | `sf project deploy start` | Push Bot + Planner + Plugin + PermissionSet |
| Fallback | `sf agent create --spec specs/seller-briefing-agent.yaml ...` | Rebuild from spec if a standard action is missing |
| Activate | `sf agent activate --api-name Seller_Briefing_Agent --version 1` | Make the agent runnable |
| Assign | `sf org assign permset --name Seller_Briefing_Agent` | Grant you runtime + object access |
| Smoke test | `sf data query ...` | Confirm the BotDefinition exists |

If anything goes sideways, the prompt tells Vibes to surface the exact error so you (or it, on a follow-up turn) can resolve it. The prompt is intentionally specific — agentic loops perform best when the goal, the order, the tools, and the failure-recovery branches are all spelled out.
