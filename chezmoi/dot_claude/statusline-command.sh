#!/bin/sh

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
model_id=$(echo "$input" | jq -r '.model.id')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Git branch
git_part=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_part=" $branch"
    fi
fi

# Context usage
ctx_part=""
if [ -n "$used" ]; then
    ctx_part=" ctx:${used}%"
fi

# Cost calculation based on model ID (prices per million tokens)
case "$model_id" in
    *opus-4*|*opus-4-5*)
        input_price="15.0"
        output_price="75.0"
        ;;
    *sonnet-4*|*sonnet-4-5*|*sonnet-4-6*)
        input_price="3.0"
        output_price="15.0"
        ;;
    *haiku-3-5*|*haiku-4*)
        input_price="0.8"
        output_price="4.0"
        ;;
    *)
        input_price="3.0"
        output_price="15.0"
        ;;
esac

cost_part=""
if [ "$total_input" -gt 0 ] 2>/dev/null || [ "$total_output" -gt 0 ] 2>/dev/null; then
    cost=$(awk -v ti="$total_input" -v to="$total_output" -v ip="$input_price" -v op="$output_price" \
        'BEGIN { cost = (ti * ip / 1000000) + (to * op / 1000000); printf "%.4f", cost }')
    cost_part=" \$${cost}"
fi

printf "%s |%s%s%s\n" "$model" "$git_part" "$ctx_part" "$cost_part"
