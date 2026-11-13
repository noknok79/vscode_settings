---
name: publish-to-confluence
description: "Publish repository documentation to Confluence using the standardized templates"
disable-model-invocation: true
argument-hint: "Source docs path and target document type/template"
---
Publish or update the requested documentation in Confluence.

Inputs to use:
- Source markdown document path in this repository
- Desired template type (T1-T8)
- Confluence page name and parent placement requirements

Execution requirements:
1. Convert markdown to Confluence storage format safely.
2. Preserve headings, tables, code blocks, and diagrams.
3. Follow naming standard: <PROJECT>_<DOCUMENT_TYPE>.
4. Support create or update workflow with version increment.
5. Return resulting page URL and page ID.

Output format:
- Action performed (created/updated)
- Page title, ID, URL
- Template used
- Any conversion caveats