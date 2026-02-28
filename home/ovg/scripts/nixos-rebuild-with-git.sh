#!/usr/bin/env bash

# --- NixOS Rebuild with Git Automation ---
# This script stages changes, commits them, pushes to remote,
# and then performs a NixOS system rebuild using Flakes.

set -e

REPO_PATH="/home/ovg/dotfiles/nix"
SCRIPT_NAME="NixOS Rebuild with Git"

echo "=== $SCRIPT_NAME ==="

# Navigate to the configuration directory
cd "$REPO_PATH" || {
	echo "Error: Could not navigate to repository at $REPO_PATH"
	exit 1
}

# Helper: Git Push with Upstream Check
push_to_remote() {
	local branch_to_push="$1"
	echo "Attempting to push changes for branch '$branch_to_push'..."
	if ! git rev-parse --abbrev-ref --symbolic-full-name "${branch_to_push}"@{u} >/dev/null 2>&1; then
		echo "Local branch '$branch_to_push' has no upstream remote."
		read -p 'Do you want to set upstream and push? (y/N): ' set_upstream_response
		if [[ "$set_upstream_response" == "y" || "$set_upstream_response" == "Y" ]]; then
			git push --set-upstream origin "$branch_to_push" || {
				echo "Error: git push --set-upstream failed."
				exit 1
			}
			echo "Set upstream and pushed to origin/$branch_to_push."
		else
			echo "Aborting: Upstream not set. Cannot push changes."
			exit 0
		fi
	else
		git push || {
			echo "Error: git push failed."
			exit 1
		}
		echo "Changes pushed."
	fi
}

# --- Phase 1: Git Staging & Committing ---
commit_performed=false

# Check for uncommitted changes
if ! git diff --quiet HEAD --; then
	echo "Uncommitted changes detected."
	read -p 'Enter commit message (default: "Automated config update"): ' commit_msg
	if [ -z "$commit_msg" ]; then
		commit_msg="Automated config update"
	fi

	git add . || {
		echo "Error: git add failed."
		exit 1
	}
	git commit -m "$commit_msg" || {
		echo "Error: git commit failed."
		exit 1
	}
	echo "Changes committed: \"$commit_msg\""
	commit_performed=true
fi

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# --- Phase 2: Branch Handling & Push ---
if [[ "$current_branch" == "master" || "$current_branch" == "main" ]]; then
	echo "You are on the '$current_branch' branch."
	echo "Options:"
	echo "  (C)ontinue on '$current_branch' and push changes."
	echo "  (b)ranch off to a new branch and push changes."
	read -p 'Choose an option (C/b, default: C): ' branch_choice
	branch_choice=${branch_choice:-C}

	case "$branch_choice" in
	[Bb]*) # Create new branch
		read -p 'Enter new branch name: ' new_branch_name
		if [ -z "$new_branch_name" ]; then
			echo "Aborting: Branch name required."
			exit 0
		fi
		if git rev-parse --verify "$new_branch_name" >/dev/null 2>&1; then
			echo "Branch '$new_branch_name' already exists locally. Switching to it."
			git checkout "$new_branch_name" || {
				echo "Error: Could not switch."
				exit 1
			}
		else
			git checkout -b "$new_branch_name" || {
				echo "Error: Could not create branch."
				exit 1
			}
		fi
		current_branch="$new_branch_name"
		echo "Switched to branch '$current_branch'."
		push_to_remote "$current_branch"
		;;
	[Cc]*) # Continue
		echo "Continuing on '$current_branch'."
		push_to_remote "$current_branch"
		;;
	*)
		echo "Invalid choice. Aborting."
		exit 0
		;;
	esac
else
	# Not on a main branch, assume standard workflow
	echo "On branch '$current_branch'."
	push_to_remote "$current_branch"
fi

# --- Phase 3: NixOS Rebuild ---
echo "--- Starting NixOS Rebuild ---"
HOSTNAME="$(hostname -s)"
sudo nixos-rebuild switch --flake ".#${HOSTNAME}" || {
	echo "Error: NixOS rebuild failed."
	exit 1
}
echo "NixOS rebuild completed successfully."

echo "Press any key to close."
read -n 1 -s -r -p ""
