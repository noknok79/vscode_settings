# Reusable prompts (session-derived)

Use `{{placeholders}}` as variables, such as `{{pipelineFile}}`, when calling a prompt.

| Prompt | Purpose | Use when |
| --- | --- | --- |
| copilot-account-check | Show the active GitHub and Copilot login | You need to know which account is signed in |
| fix-pipeline-from-log | Fix a pipeline error or failing step from a log | A pipeline or smoke-test step fails |
| acr-single-tag-push | Push exactly one vN tag to ACR | Extra tags appear in the registry |
| acr-rollback-best-practice | Smoke test, tag lock, digest-aware retention | Hardening the build and push pipeline |
| image-failure-recovery-review | Simulate failure and recovery, and design automation | You want to understand or automate recovery |
| integrate-python-smoke-test | Wire a Python validator into the pipeline | You have a smoke-test script to add |
| agent-pool-image-testing-tools | Tools to install on the agent pool | Planning image quality gates |
| create-rollback-pipeline | Manual rollback of the Container App | No rollback pipeline exists yet |
| container-app-rollback-process-review | Review the rollback process against standard | Validating the rollback design |
| review-pipeline-run-form | Check a Run pipeline form against the YAML | Verifying parameters and the UI |
| automate-acr-tag-selection | Auto-select the rollback version | You don't want to type tags |
| save-session-prompts | Save session prompts as reusable files | End of a session |
| simplify-pipeline | Simplify existing pipeline stages, jobs, and tasks while preserving behavior | You want behavior-preserving pipeline simplification |
