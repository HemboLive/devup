#!/usr/bin/env bash
set -euo pipefail

BASE="${DEVSTACK_HOME:-$HOME/devstack}"
REPOS="$BASE/repos"
CONF="$BASE/configs"
mkdir -p "$REPOS" "$CONF"

# ================= Shutdown =================
stop_project() {
  running=()
  while IFS= read -r p; do
    [[ -n "$p" ]] && running+=("$p")
  done < <(docker compose ls -q)

  if [[ ${#running[@]} -eq 0 ]]; then
    echo ">> No Docker-Compose-Projects are running."
    exit 0
  fi

  PS3="Projekt to shutdown: "
  select project in "${running[@]}"; do [[ -n "$project" ]] && break; done
  docker compose -p "$project" down
  echo ">> $project is down"
}

# ============ Start / Update ============
start_project() {
  url="${1:-}"
  branch="${2:-}"

  if [[ -z "$url" ]]; then
    [[ -f "$BASE/repos.txt" ]] || { echo "No URL in repos.txt or no repos.txt"; exit 1; }
    list=()
    while IFS= read -r line; do
      [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
      list+=("$line")
    done < "$BASE/repos.txt"
    PS3="Repo-Number: "
    select url in "${list[@]}"; do [[ -n "$url" ]] && break; done
  fi

  name="$(basename "${url%.git}")"
  dir="$REPOS/$name"
  cfg="$CONF/$name"
  mkdir -p "$cfg"

  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" fetch --all --prune
  else
    git clone "$url" "$dir"
  fi

  if [[ -z "$branch" ]]; then
    branches=()
    while IFS= read -r b; do
      branches+=("$b")
    done < <(git -C "$dir" ls-remote --heads origin | sed 's#.*refs/heads/##' | sort)

    PS3="Branch-Number: "
    select branch in "${branches[@]}"; do [[ -n "$branch" ]] && break; done
  fi

  git -C "$dir" checkout "$branch" 2>/dev/null || git -C "$dir" checkout -b "$branch" "origin/$branch"
  git -C "$dir" pull --ff-only

  exclude="$dir/.git/info/exclude"
  for f in .env docker-compose.local.yml; do
    grep -qxF "$f" "$exclude" 2>/dev/null || echo "$f" >> "$exclude"
  done

  if [[ ! -f "$cfg/.env" && -f "$dir/.env.example" ]]; then
    cp "$dir/.env.example" "$cfg/.env"
    echo ">> $cfg/.env from .env.example generatet. Please modify the .env at config folder and start again."
    exit 0
  fi
  [[ -f "$cfg/.env" ]] && cp "$cfg/.env" "$dir/.env"

  compose_args=()
  if [[ -f "$cfg/docker-compose.yml" ]]; then
    cp "$cfg/docker-compose.yml" "$dir/docker-compose.local.yml"
    compose_args+=(-f docker-compose.local.yml)
  fi

  project="$(echo "${name}-${branch}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_\n-' '-')"
  cd "$dir"
  docker compose -p "$project" ${compose_args[@]+"${compose_args[@]}"} up -d --build
  echo ">> $name ($branch) running as projekt '$project'"
}

# ================ MAINMENU ================
case "${1:-}" in
  stop)
    stop_project
    ;;
  "")
    PS3="Action: "
    select action in "Repo update & start" "Docker shutdown"; do
      case "$REPLY" in
        1) start_project; break ;;
        2) stop_project; break ;;
      esac
    done
    ;;
  *)
    start_project "$@"
    ;;
esac