#!/bin/bash

set -e

# 解析參數
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --gitlab-url) GITLAB_URL="$2"; shift ;;
        --private-token) PRIVATE_TOKEN="$2"; shift ;;
        --source-group-id) SOURCE_GROUP_ID="$2"; shift ;;
        --target-group-id) TARGET_GROUP_ID="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# 驗證參數
if [[ -z "$GITLAB_URL" || -z "$PRIVATE_TOKEN" || -z "$SOURCE_GROUP_ID" || -z "$TARGET_GROUP_ID" ]]; then
    echo "Missing required arguments."
    exit 1
fi

HEADER="PRIVATE-TOKEN: $PRIVATE_TOKEN"

function retry_curl() {
    local attempt=0
    local max_retries=3
    local delay=3
    until "$@"; do
        attempt=$(( attempt + 1 ))
        if [[ $attempt -ge $max_retries ]]; then
            echo "Retry failed after $attempt attempts."
            return 1
        fi
        echo "Retrying ($attempt/$max_retries)..."
        sleep $delay
    done
}

function fork_project() {
    local project_id="$1"
    local target_ns_id="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would fork project ID $project_id to group ID $target_ns_id"
        return
    fi

    echo "Forking project ID $project_id to group ID $target_ns_id"

    retry_curl curl -sS -X POST \
        -H "$HEADER" \
        "$GITLAB_URL/api/v4/projects/$project_id/fork?namespace_id=$target_ns_id"
}

function copy_group_contents() {
    local group_id="$1"
    local target_group_id="$2"

    # 專案處理
    local projects=$(curl -sS -H "$HEADER" "$GITLAB_URL/api/v4/groups/$group_id/projects?per_page=100")
    echo "$projects" | jq -c '.[]' | while read -r project; do
        local project_id=$(echo "$project" | jq -r '.id')
        fork_project "$project_id" "$target_group_id"
    done

    # 子群組處理
    local subgroups=$(curl -sS -H "$HEADER" "$GITLAB_URL/api/v4/groups/$group_id/subgroups?per_page=100")
    echo "$subgroups" | jq -c '.[]' | while read -r subgroup; do
        local sub_id=$(echo "$subgroup" | jq -r '.id')
        local sub_name=$(echo "$subgroup" | jq -r '.name')
        local sub_path=$(echo "$subgroup" | jq -r '.path')

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would create subgroup $sub_name under group ID $target_group_id"
            local new_subgroup_id="fake_$sub_name"
        else
            echo "Creating subgroup $sub_name under group ID $target_group_id"
            local new_subgroup=$(curl -sS -X POST -H "$HEADER" \
                -H "Content-Type: application/json" \
                -d "{\"name\": \"$sub_name\", \"path\": \"$sub_path\", \"parent_id\": $target_group_id}" \
                "$GITLAB_URL/api/v4/groups")
            local new_subgroup_id=$(echo "$new_subgroup" | jq -r '.id')
        fi

        # 遞迴
        if [[ "$DRY_RUN" == true ]]; then
            copy_group_contents "$sub_id" "$new_subgroup_id"
        else
            copy_group_contents "$sub_id" "$new_subgroup_id"
        fi
    done
}

if [[ "$DRY_RUN" == true ]]; then
    echo "=================================================="
    echo "DRY RUN MODE - No actual operations will be performed"
    echo "=================================================="
fi

copy_group_contents "$SOURCE_GROUP_ID" "$TARGET_GROUP_ID"

if [[ "$DRY_RUN" == true ]]; then
    echo "=================================================="
    echo "DRY RUN COMPLETED - No changes were made"
    echo "=================================================="
else
    echo "=================================================="
    echo "OPERATION COMPLETED SUCCESSFULLY"
    echo "=================================================="
fi
