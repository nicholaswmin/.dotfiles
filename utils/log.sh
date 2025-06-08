#!/bin/bash
#
# This file defines standard logger functions,
# with support for NO_COLOR/FORCE_COLOR conventions.
# Their usage is standard, for example:
#
#   log "Doing a thing..."
#   log_error "A thing failed."
#
# However, `log_error` and `log_done` also support Actionable Messages
# via the rest of their parameters. For example:
#
#   log_error "Nginx config missing." \
#     "- check that Nginx is installed"
#
# Actionable Messages are meant to inform the user about what to do next,
# enabling a UX that's as frictionless as possible.
#
# These messages are **entirely optional**. 
# Use them to inform, not to misinform. 
#
# If an actionable message:
# - lacks clear actionable steps
# - is too complex to describe here.
# or you're just not confident about its relevance, 
# it is always better to:
# - log as you would, i.e: `log_error "a thing.json is missing"`
# - just omit the actionable message.
#
# Usage:
# 1. Write your script with basic logging:
#    e.g.: `log_done "foobar completed"`, `log_error "missing foobar.json"`.
# 2. Give the entire script and this guide, as prompt to an LLM.
# 3. Ask it to enhance the log calls with Actionable Messages and to
#    provide a summary of changes for verification.
#
# **  block contains machine-readable instructions for an LLM **
# **  outputs edited script, summary of changes done for verification **
# ==============================================================================
# <llm_instructions>
#
# <system_prompt>
# You are an expert shell script developer. Your task is to apply these
# instructions to user-provided shell scripts.
#
# <thinking_process>
#   1. Identify the core task: Is it an error (`log_error`) or a success (`log_done`)?
#   2. Draft the primary message (Parameter 1) based on the user's request.
#   3. Brainstorm actionable suggestions or next steps. Discard any that are not
#      genuinely helpful.
#   4. Format each suggestion/step according to the <ruleset for="message_content">.
#   5. Construct the final shell code according to the <ruleset for="source_code">.
# </thinking_process>
#
# <deliverables>
#   Your final output MUST consist of two parts:
#   1. The complete, refactored shell script inside a code block.
#   2. A concise summary of the changes you made inside a <changes> block.
#   Do not include any other conversational text or explanations.
# </deliverables>
# </system_prompt>
#
# <api_definition>
#   <concept name="Actionable Messages">
#     <type name="Suggestions" for="log_error">
#       Actions to resolve a failed step.
#     </type>
#     <type name="Next Steps" for="log_done">
#       Guidance following a successful step.
#     </type>
#   </concept>
#   <function name="log_error">
#     <purpose>Logs a failure message in RED.</purpose>
#     <signature>log_error(error_message, [suggestion_1], ...)</signature>
#     <param name="error_message" required="true">What failed.</param>
#     <param name="suggestion_n" required="false">How to fix the error.</param>
#   </function>
#   <function name="log_done">
#     <purpose>Logs a success message in GREEN.</purpose>
#     <signature>log_done(success_message, [next_step_1], ...)</signature>
#     <param name="success_message" required="true">What succeeded.</param>
#     <param name="next_step_n" required="false">User's next steps.</param>
#   </function>
# </api_definition>
#
# <ruleset for="message_content">
#   <!-- Applies to all 'suggestion' and 'next_step' parameters -->
#   <rule id="relevancy">If no suggestion is genuinely helpful, OMIT it.</rule>
#   <rule id="tone">Be direct and telegraphic. AVOID filler words ("Please", "Try to").</rule>
#   <rule id="layout_bullet">Each new suggestion/step MUST start with "- " (dash, space).</rule>
#   <rule id="layout_indent">Indent wrapped lines of the same suggestion with two spaces.</rule>
#   <rule id="layout_command">A user-runnable command MUST be on its own indented line.</rule>
#   <rule id="linelength">Target ~70 chars per line; HARD LIMIT of 80 (URLs excepted).</rule>
# </ruleset>
#
# <ruleset for="source_code">
#   <!-- Applies to how you write the function calls in this script -->
#   <rule id="multiline">Calls with more than one argument MUST be multi-line.</rule>
#   <rule id="indentation">Use SPACES only for indentation.</rule>
#   <rule id="heredocs">PREFER heredocs (`<<-EOF`) for all multi-line suggestions/steps.</rule>
#   <rule id="heredoc_delimiter">The closing `EOF` delimiter MUST be on its own line with NO whitespace.</rule>
# </ruleset>
#
# <examples>
#   <good_example comment="Error with a multi-line suggestion using heredoc.">
#     ERROR_SUGGESTION=$(cat <<-EOF
#     - check which process is using port 8080 with this command:
#       sudo lsof -i :8080
#     - stop the conflicting process or use a different port
#     EOF
#     )
#     log_error "Service failed to start: Port 8080 is already in use" \
#       "${ERROR_SUGGESTION}"
#   </good_example>
# 
#   <good_example comment="Success message with a next step.">
#     DONE_NEXT_STEP=$(cat <<-EOF
#     - confirm backup file integrity by running:
#       sha256sum /mnt/backups/latest.bak
#     EOF
#     )
#     log_done "System backup completed successfully" \
#       "${DONE_NEXT_STEP}"
#   </good_example>
# 
#   <good_example comment="Error with a single, simple suggestion (no heredoc).">
#     log_error "Config file not found: /etc/app/config.yml" \
#       "- create a new config from template: cp config.yml.example /etc/app/config.yml"
#   </good_example>
# 
#   <good_example comment="Error with no suggestions, per relevancy rule.">
#     log_error "Critical failure: Unrecoverable kernel panic"
#   </good_example>
# 
#   <bad_example>
#     <!-- This example violates rules: multiline, heredocs, layout_command, tone. -->
#     log_error "Port in use" "The port is in use, so you should check it with lsof -i :8080 or change it."
#   </bad_example>
# </examples>
#
# <sources>
#   <!-- This instruction block was optimized using the following Anthropic guidelines -->
#   <guideline name="Use XML Tags">
#     <detail>Uses nested XML tags (e.g., <system_prompt>, <ruleset>) for clarity and robust parsing.</detail>
#   </guideline>
#   <guideline name="Use System Prompts">
#     <detail>A dedicated <system_prompt> sets the persona, core mission, and context at the beginning of the instructions.</detail>
#   </guideline>
#   <guideline name="Chain of Thought &amp; Extended Thinking">
#     <detail>The system prompt includes a numbered "thinking process" to guide the model's reasoning before it generates code.</detail>
#   </guideline>
#   <guideline name="Be Clear and Direct">
#     <detail>Rules use imperative, direct language (e.g., "MUST", "AVOID") to minimize ambiguity.</detail>
#   </guideline>
#   <guideline name="Provide Examples">
#     <detail>A dedicated <examples> block with <good_example> and <bad_example> provides concrete, annotated demonstrations.</detail>
#   </guideline>
# </sources>
#
# </llm_instructions>
# ==============================================================================

color() {
  if [ -n "$NO_COLOR" ] || { [ ! -t 1 ] && [ -z "$FORCE_COLOR" ]; } || \
     ! command -v tput >/dev/null; then
    printf "%s" "$2"
    return
  fi

  printf "%s%s%s" "$(tput "$1")" "$2" "$(tput sgr0)"
}

log() {
  for msg in "$@"; do
    printf "%s\n" "$(color dim "$msg")"
  done
}

log_warn() {
  for msg in "$@"; do
    printf "%s\n" "$(color setaf 3 "› warn: $msg")"
  done
}

log_done() {
  printf "%s\n" "$(color setaf 2 "› $1")"
  shift
  log "$@"
}

log_error() {
  printf "%s\n" "$(color setaf 1 "› error: $1")" >&2
  shift
  log "$@" >&2
}