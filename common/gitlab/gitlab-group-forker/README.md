
# README

## Usage

Run the script with the following parameters:
```bash
./your_script_name.sh \
  --gitlab-url <YOUR_GITLAB_URL> \
  --private-token <YOUR_PRIVATE_TOKEN> \
  --source-group-id <SOURCE_GROUP_ID> \
  --target-group-id <TARGET_GROUP_ID> \
  [--dry-run]
```

---

## Arguments

- `--gitlab-url`: The base URL of your GitLab instance (e.g., `https://gitlab.com`).
- `--private-token`: A **GitLab private access token** with `api` scope permissions. This token needs sufficient permissions to read from the source group and create/fork projects and groups in the target group.
- `--source-group-id`: The **ID of the source GitLab group** whose contents you want to copy.
- `--target-group-id`: The **ID of the target GitLab group** where projects will be forked and subgroups will be created.
- `--dry-run` (optional): If included, the script will **simulate the operations** without making any actual changes to your GitLab instance. This is highly recommended for testing before a real run.

---

## How it Works

The script performs the following actions:

1. **Parses arguments**: It reads the provided GitLab URL, private token, source and target group IDs, and checks for the dry run flag.
2. **Validates arguments**: Ensures all required parameters are provided.
3. **Retries API calls**: Includes a retry mechanism for `curl` commands to handle transient network issues or API rate limits.
4. **Forks projects**: Iterates through all projects in the `source-group-id` and forks them into the `target-group-id`.
5. **Replicates subgroups**:
    - Fetches all immediate subgroups within the `source-group-id`.
    - For each subgroup, it creates a new subgroup with the same name and path under the `target-group-id`.
    - **Recursively calls itself** to process projects and subgroups within the newly created subgroup, effectively mirroring the entire group structure.

---

## Requirements

- `bash`: The script is written in Bash.
- `curl`: Used for making API requests to GitLab.
- `jq`: A lightweight and flexible command-line JSON processor. It's used to parse the JSON responses from the GitLab API.

You can install `jq` using your system's package manager (e.g., `sudo apt-get install jq` on Debian/Ubuntu, `brew install jq` on macOS).

---

## Important Notes

- **Permissions**: Ensure your `PRIVATE_TOKEN` has the necessary permissions to read projects and subgroups from the source group and create/fork projects and subgroups in the target group.
- **Rate Limiting**: For large groups with many projects and subgroups, you might encounter GitLab API rate limits. The script includes a basic retry mechanism, but for very large operations, you might need to adjust the `delay` in the `retry_curl` function or consider running it during off-peak hours.
- **Existing Projects/Groups**: If a project with the same path already exists when forking, or a subgroup with the same name/path exists when creating, GitLab's API will likely return an error. This script does not currently handle overwriting or updating existing resources.
- **Dry Run**: Always perform a **dry run** first to understand what changes will be made before executing the script in production.
