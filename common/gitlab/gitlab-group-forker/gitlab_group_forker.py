import argparse
import gitlab
import time

def retry(func, max_retries=3, delay=3, *args, **kwargs):
    for attempt in range(max_retries):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            print(f"Error: {e}, retrying {attempt + 1}/{max_retries}")
            time.sleep(delay)
    raise Exception(f"Failed after {max_retries} retries")

def fork_project(gl, project, target_namespace_id, dry_run=False):
    if dry_run:
        print(f"[DRY RUN] Would fork project {project.path_with_namespace} to group ID {target_namespace_id}")
        return None
    else:
        print(f"Forking project {project.path_with_namespace} to group ID {target_namespace_id}")
        return retry(project.forks.create, project=project.id, namespace_id=target_namespace_id)

def copy_group_contents(gl, source_group, target_group_id, dry_run=False):
    if dry_run:
        print(f"[DRY RUN] Would copy contents from {source_group.full_path} to group ID {target_group_id}")
    else:
        print(f"Copying contents from {source_group.full_path} to group ID {target_group_id}")

    # Fork repositories
    for project in source_group.projects.list(all=True):
        project_full = gl.projects.get(project.id)
        fork_project(gl, project_full, target_group_id, dry_run)

    # Recursively handle subgroups
    for subgroup in source_group.subgroups.list(all=True):
        full_subgroup = gl.groups.get(subgroup.id)

        if dry_run:
            print(f"[DRY RUN] Would create subgroup {full_subgroup.name} in target group ID {target_group_id}")
            # In dry run mode, simulate subgroup creation with a fake ID
            new_subgroup_id = f"fake_subgroup_id_for_{full_subgroup.name}"
        else:
            print(f"Creating subgroup {full_subgroup.name} in target group ID {target_group_id}")
            new_subgroup = gl.groups.create({
                'name': full_subgroup.name,
                'path': full_subgroup.path,
                'parent_id': target_group_id
            })
            new_subgroup_id = new_subgroup.id

        # Recursively copy content
        copy_group_contents(gl, full_subgroup, new_subgroup_id, dry_run)

def main():
    parser = argparse.ArgumentParser(description='GitLab Group Content Copier')
    parser.add_argument('--gitlab-url', required=True)
    parser.add_argument('--private-token', required=True)
    parser.add_argument('--source-group-id', type=int, required=True, help='ID of the group to copy from')
    parser.add_argument('--target-group-id', type=int, required=True, help='ID of the group to copy into')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without actually performing any operations')
    args = parser.parse_args()

    gl = gitlab.Gitlab(args.gitlab_url, private_token=args.private_token)
    gl.auth()

    source_group = gl.groups.get(args.source_group_id)
    target_group = gl.groups.get(args.target_group_id)

    if args.dry_run:
        print("=" * 50)
        print("DRY RUN MODE - No actual operations will be performed")
        print("=" * 50)

    copy_group_contents(gl, source_group, target_group.id, args.dry_run)

    if args.dry_run:
        print("=" * 50)
        print("DRY RUN COMPLETED - No changes were made")
        print("=" * 50)
    else:
        print("=" * 50)
        print("OPERATION COMPLETED SUCCESSFULLY")
        print("=" * 50)

if __name__ == '__main__':
    main()
