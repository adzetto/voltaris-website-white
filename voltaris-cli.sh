#!/bin/bash

# =================================================================
# Voltaris Website CLI Management Tool
# Features:
# - Deploy to GitHub Pages
# - Create backups of critical files
# - Restore from backups
# - Track deployment history
# - View deployment logs
# =================================================================

# ANSI color codes for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./voltaris-backups"
LOGS_DIR="./voltaris-logs"
CONFIG_FILE="./voltaris-cli-config.json"
DEFAULT_BRANCH="main"
MAX_BACKUPS=10  # Maximum number of backups to keep

# Files to backup (prioritizing JSON files and critical configs)
BACKUP_FILES=(
  "package.json"
  "package-lock.json"
  ".env"
  "tailwind.config.js"
  "postcss.config.js"
  "config-overrides.js"
  "webpack.config.js"
)

# =======================
# UTILITY FUNCTIONS
# =======================

# Initialize the environment
initialize() {
  echo -e "${BLUE}${BOLD}Initializing Voltaris CLI environment...${NC}"
  
  # Create backup directory
  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}✓ Created backup directory${NC}"
  fi
  
  # Create logs directory
  if [ ! -d "$LOGS_DIR" ]; then
    mkdir -p "$LOGS_DIR"
    echo -e "${GREEN}✓ Created logs directory${NC}"
  fi
  
  # Create/check config file
  if [ ! -f "$CONFIG_FILE" ]; then
    echo '{
      "branch": "main",
      "last_deployment": null,
      "total_deployments": 0,
      "backups": []
    }' > "$CONFIG_FILE"
    echo -e "${GREEN}✓ Created configuration file${NC}"
  fi
  
  echo -e "${GREEN}${BOLD}Environment ready!${NC}\n"
}

# Update config file with new data
update_config() {
  local key=$1
  local value=$2
  
  # Use temp file for more complex updates
  local temp_file="$CONFIG_FILE.tmp"
  jq ".$key = $value" "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
}

# Add a backup entry to config
add_backup_entry() {
  local backup_id=$1
  local backup_date=$(date '+%Y-%m-%d %H:%M:%S')
  local backup_path=$2
  local description=$3
  
  local temp_file="$CONFIG_FILE.tmp"
  jq ".backups |= . + [{\"id\": \"$backup_id\", \"date\": \"$backup_date\", \"path\": \"$backup_path\", \"description\": \"$description\"}]" "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
  
  # If we exceed max backups, remove the oldest
  local backup_count=$(jq '.backups | length' "$CONFIG_FILE")
  if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
    # Get the oldest backup path
    local oldest_backup=$(jq -r '.backups[0].path' "$CONFIG_FILE")
    # Remove the oldest backup file
    if [ -d "$oldest_backup" ]; then
      rm -rf "$oldest_backup"
      echo -e "${YELLOW}Removed old backup: $oldest_backup${NC}"
    fi
    # Remove the entry from the config file
    jq '.backups = .backups[1:]' "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
  fi
}

# Log events
log_event() {
  local event_type=$1
  local description=$2
  local log_file="$LOGS_DIR/voltaris-$(date '+%Y-%m').log"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$event_type] $description" >> "$log_file"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validate dependencies
check_dependencies() {
  local missing=0
  
  echo -e "${BLUE}${BOLD}Checking dependencies...${NC}"
  
  if ! command_exists git; then
    echo -e "${RED}✗ Git not found${NC}"
    missing=1
  else
    echo -e "${GREEN}✓ Git detected${NC}"
  fi
  
  if ! command_exists npm; then
    echo -e "${RED}✗ npm not found${NC}"
    missing=1
  else
    echo -e "${GREEN}✓ npm detected${NC}"
  fi
  
  if ! command_exists jq; then
    echo -e "${RED}✗ jq not found (required for JSON processing)${NC}"
    echo -e "${YELLOW}Please install jq: https://stedolan.github.io/jq/download/${NC}"
    missing=1
  else
    echo -e "${GREEN}✓ jq detected${NC}"
  fi
  
  if [ $missing -eq 1 ]; then
    echo -e "${RED}${BOLD}Missing dependencies. Please install them before proceeding.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}${BOLD}All dependencies satisfied!${NC}\n"
}

# Show spinner for long operations
spinner() {
  local pid=$1
  local message=$2
  local spin='-\|/'
  local i=0
  
  echo -ne "${YELLOW}$message... ${NC}"
  
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r${YELLOW}$message... ${BOLD}${spin:$i:1}${NC}"
    sleep .1
  done
  
  printf "\r${GREEN}$message... Done!${NC}\n"
}

# Check git status
check_git_status() {
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}${BOLD}Error: Not a git repository.${NC}"
    exit 1
  fi
  
  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}${BOLD}Warning: You have uncommitted changes.${NC}"
    return 1
  fi
  
  return 0
}

# =======================
# FEATURE FUNCTIONS
# =======================

# Create a backup
create_backup() {
  local description=$1
  local backup_id=$(date '+%Y%m%d-%H%M%S')
  local backup_path="$BACKUP_DIR/$backup_id"
  
  echo -e "${BLUE}${BOLD}Creating backup $backup_id...${NC}"
  
  # Create backup directory
  mkdir -p "$backup_path"
  
  # Copy critical files
  for file in "${BACKUP_FILES[@]}"; do
    if [ -f "$file" ]; then
      cp "$file" "$backup_path/"
      echo -e "${GREEN}✓ Backed up $file${NC}"
    else
      echo -e "${YELLOW}⚠ File $file not found, skipping${NC}"
    fi
  done
  
  # Create a snapshot of the build directory if it exists
  if [ -d "build" ]; then
    mkdir -p "$backup_path/build"
    cp -r build/* "$backup_path/build/"
    echo -e "${GREEN}✓ Backed up build directory${NC}"
  fi
  
  # Store git status
  git log -1 --format="%H%n%an%n%ad%n%s" > "$backup_path/git-status.txt"
  echo -e "${GREEN}✓ Saved git commit information${NC}"
  
  # Update config with backup info
  if [ -z "$description" ]; then
    description="Automated backup"
  fi
  add_backup_entry "$backup_id" "$backup_path" "$description"
  
  # Log the event
  log_event "BACKUP" "Created backup $backup_id: $description"
  
  echo -e "${GREEN}${BOLD}Backup $backup_id created successfully!${NC}"
  return 0
}

# Restore from a backup
restore_backup() {
  local backup_id=$1
  
  if [ -z "$backup_id" ]; then
    echo -e "${RED}${BOLD}Error: Backup ID is required.${NC}"
    echo -e "Use ${CYAN}./voltaris-cli.sh backups${NC} to see available backups."
    return 1
  fi
  
  # Verify backup exists
  local backup_path=$(jq -r ".backups[] | select(.id == \"$backup_id\") | .path" "$CONFIG_FILE")
  if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
    echo -e "${RED}${BOLD}Error: Backup $backup_id not found.${NC}"
    return 1
  fi
  
  echo -e "${YELLOW}${BOLD}Warning: This will overwrite your current configuration files!${NC}"
  read -p "Are you sure you want to continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restoration cancelled.${NC}"
    return 1
  fi
  
  echo -e "${BLUE}${BOLD}Restoring from backup $backup_id...${NC}"
  
  # First create a backup of the current state
  create_backup "Pre-restore backup"
  
  # Restore files
  for file in "${BACKUP_FILES[@]}"; do
    if [ -f "$backup_path/$file" ]; then
      cp "$backup_path/$file" "./$file"
      echo -e "${GREEN}✓ Restored $file${NC}"
    fi
  done
  
  # Restore build if it exists in the backup
  if [ -d "$backup_path/build" ]; then
    rm -rf ./build
    mkdir -p ./build
    cp -r "$backup_path/build"/* ./build/
    echo -e "${GREEN}✓ Restored build directory${NC}"
  fi
  
  # Log the event
  log_event "RESTORE" "Restored from backup $backup_id"
  
  echo -e "${GREEN}${BOLD}Restoration from backup $backup_id completed!${NC}"
  echo -e "${YELLOW}Note: This only restored configuration files, not your source code.${NC}"
  return 0
}

# List all backups
list_backups() {
  echo -e "${BLUE}${BOLD}Available backups:${NC}"
  
  # Check if we have any backups
  local backup_count=$(jq '.backups | length' "$CONFIG_FILE")
  if [ "$backup_count" -eq 0 ]; then
    echo -e "${YELLOW}No backups found.${NC}"
    return 0
  fi
  
  # Print header
  printf "${CYAN}%-20s %-25s %-40s${NC}\n" "BACKUP ID" "DATE" "DESCRIPTION"
  echo "--------------------------------------------------------------------------------"
  
  # Print each backup
  jq -r '.backups[] | "\(.id) \(.date) \(.description)"' "$CONFIG_FILE" | \
  while read -r id date description; do
    printf "${GRAY}%-20s %-25s %-40s${NC}\n" "$id" "$date" "$description"
  done
  
  echo "--------------------------------------------------------------------------------"
  echo -e "${GRAY}To restore a backup: ${CYAN}./voltaris-cli.sh restore <BACKUP_ID>${NC}"
  
  return 0
}

# Show deployment history
show_history() {
  echo -e "${BLUE}${BOLD}Deployment history:${NC}"
  
  if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR")" ]; then
    echo -e "${YELLOW}No deployment logs found.${NC}"
    return 0
  fi
  
  # Print last 10 deployments from logs
  echo "--------------------------------------------------------------------------------"
  grep -h "\[DEPLOY\]" "$LOGS_DIR"/*.log | tail -n 10 | \
  while read -r line; do
    echo -e "${GRAY}$line${NC}"
  done
  echo "--------------------------------------------------------------------------------"
  
  # Show total stats
  local total_deployments=$(jq '.total_deployments' "$CONFIG_FILE")
  local last_deployment=$(jq -r '.last_deployment' "$CONFIG_FILE")
  
  echo -e "${GRAY}Total deployments: ${CYAN}$total_deployments${NC}"
  if [ "$last_deployment" != "null" ]; then
    echo -e "${GRAY}Last deployment: ${CYAN}$last_deployment${NC}"
  fi
  
  return 0
}

# Deploy the website
deploy_website() {
  local commit_message=$1
  local skip_build=$2
  local skip_backup=$3
  
  echo -e "${BLUE}${BOLD}Starting website deployment...${NC}"
  
  # Check git status first
  check_git_status
  local git_status=$?
  
  # Create backup before deploying (unless skipped)
  if [ "$skip_backup" != "true" ]; then
    create_backup "Pre-deployment backup"
  fi
  
  # Build the project (unless skipped)
  if [ "$skip_build" != "true" ]; then
    echo -e "${YELLOW}Building the project...${NC}"
    npm run build &
    build_pid=$!
    spinner $build_pid "Building"
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}Build failed. Aborting deployment.${NC}"
      log_event "DEPLOY" "Failed: Build error"
      return 1
    fi
    echo -e "${GREEN}✓ Build successful${NC}"
  else
    echo -e "${YELLOW}Skipping build phase as requested.${NC}"
  fi
  
  # Add all changes to git
  echo -e "${YELLOW}Adding all changes to git...${NC}"
  git add .
  
  # Get commit message if not provided
  if [ -z "$commit_message" ]; then
    echo -e "${YELLOW}Please enter a commit message:${NC}"
    read -p "> " commit_message
    
    if [ -z "$commit_message" ]; then
      commit_message="Update website content $(date '+%Y-%m-%d %H:%M:%S')"
      echo -e "${YELLOW}No message provided. Using default: ${NC}${commit_message}"
    fi
  fi
  
  # Commit changes
  echo -e "${YELLOW}Committing changes...${NC}"
  git commit -m "$commit_message"
  
  # Push to GitHub
  echo -e "${YELLOW}Pushing to GitHub...${NC}"
  local branch=$(jq -r '.branch' "$CONFIG_FILE")
  if [ "$branch" == "null" ]; then
    branch="$DEFAULT_BRANCH"
  fi
  
  git push origin $branch
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}Push failed. Please check your network connection or repository access.${NC}"
    log_event "DEPLOY" "Failed: Git push error"
    return 1
  fi
  echo -e "${GREEN}✓ Push successful${NC}"
  
  # Update deployment tracking
  local deployment_date=$(date '+%Y-%m-%d %H:%M:%S')
  update_config "last_deployment" "\"$deployment_date\""
  
  local total_deployments=$(jq '.total_deployments' "$CONFIG_FILE")
  total_deployments=$((total_deployments + 1))
  update_config "total_deployments" "$total_deployments"
  
  # Log the event
  log_event "DEPLOY" "Success: $commit_message"
  
  # Deployment complete
  echo -e "\n${GREEN}${BOLD}=== Deployment process complete! ===${NC}"
  echo -e "${YELLOW}Your changes have been pushed to GitHub.${NC}"
  echo -e "${YELLOW}GitHub Actions will now deploy your website to GitHub Pages.${NC}"
  echo -e "${YELLOW}You can check the progress in the 'Actions' tab of your GitHub repository.${NC}"
  echo -e "${GRAY}Deployment time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  
  return 0
}

# Show logs
show_logs() {
  local lines=$1
  
  if [ -z "$lines" ]; then
    lines=20
  fi
  
  echo -e "${BLUE}${BOLD}Recent logs (last $lines entries):${NC}"
  
  if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR")" ]; then
    echo -e "${YELLOW}No logs found.${NC}"
    return 0
  fi
  
  # Find the most recent log file
  local latest_log=$(ls -t "$LOGS_DIR"/*.log | head -1)
  
  # Display the logs with colors based on event type
  tail -n "$lines" "$latest_log" | while read -r line; do
    if [[ "$line" == *"[DEPLOY]"* ]]; then
      echo -e "${CYAN}$line${NC}"
    elif [[ "$line" == *"[BACKUP]"* ]]; then
      echo -e "${GREEN}$line${NC}"
    elif [[ "$line" == *"[RESTORE]"* ]]; then
      echo -e "${PURPLE}$line${NC}"
    elif [[ "$line" == *"[ERROR]"* ]]; then
      echo -e "${RED}$line${NC}"
    else
      echo -e "${GRAY}$line${NC}"
    fi
  done
  
  return 0
}

# Display help
show_help() {
  echo -e "${BLUE}${BOLD}Voltaris Website CLI - Help${NC}"
  echo -e "${GRAY}A comprehensive tool for managing your Voltaris website${NC}\n"
  
  echo -e "${CYAN}USAGE:${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh <command> [options]${NC}\n"
  
  echo -e "${CYAN}COMMANDS:${NC}"
  echo -e "  ${GREEN}deploy${NC}    ${GRAY}Deploy the website to GitHub Pages${NC}"
  echo -e "  ${GREEN}backup${NC}    ${GRAY}Create a backup of critical files${NC}"
  echo -e "  ${GREEN}restore${NC}   ${GRAY}Restore from a backup${NC}"
  echo -e "  ${GREEN}backups${NC}   ${GRAY}List all available backups${NC}"
  echo -e "  ${GREEN}history${NC}   ${GRAY}Show deployment history${NC}"
  echo -e "  ${GREEN}logs${NC}      ${GRAY}Show recent logs${NC}"
  echo -e "  ${GREEN}status${NC}    ${GRAY}Show current project status${NC}"
  echo -e "  ${GREEN}help${NC}      ${GRAY}Show this help message${NC}\n"
  
  echo -e "${CYAN}OPTIONS:${NC}"
  echo -e "  ${GREEN}deploy${NC}"
  echo -e "    ${YELLOW}-m, --message${NC}    ${GRAY}Specify commit message${NC}"
  echo -e "    ${YELLOW}-s, --skip-build${NC} ${GRAY}Skip the build process${NC}"
  echo -e "    ${YELLOW}-n, --no-backup${NC}  ${GRAY}Skip creating a backup${NC}\n"
  
  echo -e "  ${GREEN}backup${NC}"
  echo -e "    ${YELLOW}-d, --description${NC} ${GRAY}Specify backup description${NC}\n"
  
  echo -e "  ${GREEN}restore${NC}"
  echo -e "    ${YELLOW}<backup-id>${NC}       ${GRAY}ID of the backup to restore${NC}\n"
  
  echo -e "  ${GREEN}logs${NC}"
  echo -e "    ${YELLOW}-n, --lines${NC}       ${GRAY}Number of log lines to show (default: 20)${NC}\n"
  
  echo -e "${CYAN}EXAMPLES:${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh deploy -m \"Updated home page\"${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh backup -d \"Before major changes\"${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh restore 20230415-123045${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh logs -n 50${NC}\n"
  
  return 0
}

# Show status
show_status() {
  echo -e "${BLUE}${BOLD}Voltaris Website Status${NC}"
  
  # Git status
  echo -e "\n${CYAN}Git Status:${NC}"
  git_branch=$(git branch --show-current)
  git_commit=$(git rev-parse --short HEAD)
  git_message=$(git log -1 --pretty=%B)
  
  echo -e "${GRAY}Branch:${NC} ${GREEN}$git_branch${NC}"
  echo -e "${GRAY}Commit:${NC} ${GREEN}$git_commit${NC}"
  echo -e "${GRAY}Message:${NC} ${GREEN}$git_message${NC}"
  
  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}You have uncommitted changes.${NC}"
    git status -s
  else
    echo -e "${GREEN}Working directory clean.${NC}"
  fi
  
  # Project stats
  echo -e "\n${CYAN}Project Stats:${NC}"
  
  local total_deployments=$(jq '.total_deployments' "$CONFIG_FILE")
  local last_deployment=$(jq -r '.last_deployment' "$CONFIG_FILE")
  local backup_count=$(jq '.backups | length' "$CONFIG_FILE")
  
  echo -e "${GRAY}Total deployments:${NC} ${GREEN}$total_deployments${NC}"
  if [ "$last_deployment" != "null" ]; then
    echo -e "${GRAY}Last deployment:${NC} ${GREEN}$last_deployment${NC}"
  else
    echo -e "${GRAY}Last deployment:${NC} ${YELLOW}Never${NC}"
  fi
  echo -e "${GRAY}Available backups:${NC} ${GREEN}$backup_count${NC}"
  
  # Check npm dependencies
  echo -e "\n${CYAN}Dependencies:${NC}"
  outdated_count=$(npm outdated --parseable | wc -l)
  if [ "$outdated_count" -gt 0 ]; then
    echo -e "${YELLOW}You have $outdated_count outdated dependencies.${NC}"
    echo -e "${GRAY}Run ${CYAN}npm outdated${GRAY} for details.${NC}"
  else
    echo -e "${GREEN}All dependencies are up to date.${NC}"
  fi
  
  return 0
}

# =======================
# MAIN EXECUTION
# =======================

# Check for dependencies
check_dependencies

# Initialize environment
initialize

# Process arguments
COMMAND=${1:-help}
shift

case $COMMAND in
  deploy)
    # Process deploy options
    COMMIT_MESSAGE=""
    SKIP_BUILD=false
    SKIP_BACKUP=false
    
    while [[ $# -gt 0 ]]; do
      case $1 in
        -m|--message)
          COMMIT_MESSAGE="$2"
          shift 2
          ;;
        -s|--skip-build)
          SKIP_BUILD=true
          shift
          ;;
        -n|--no-backup)
          SKIP_BACKUP=true
          shift
          ;;
        *)
          echo -e "${RED}Unknown option: $1${NC}"
          show_help
          exit 1
          ;;
      esac
    done
    
    deploy_website "$COMMIT_MESSAGE" "$SKIP_BUILD" "$SKIP_BACKUP"
    ;;
    
  backup)
    # Process backup options
    DESCRIPTION=""
    
    while [[ $# -gt 0 ]]; do
      case $1 in
        -d|--description)
          DESCRIPTION="$2"
          shift 2
          ;;
        *)
          echo -e "${RED}Unknown option: $1${NC}"
          show_help
          exit 1
          ;;
      esac
    done
    
    create_backup "$DESCRIPTION"
    ;;
    
  restore)
    BACKUP_ID=$1
    restore_backup "$BACKUP_ID"
    ;;
    
  backups)
    list_backups
    ;;
    
  history)
    show_history
    ;;
    
  logs)
    # Process logs options
    LINES=20
    
    while [[ $# -gt 0 ]]; do
      case $1 in
        -n|--lines)
          LINES="$2"
          shift 2
          ;;
        *)
          echo -e "${RED}Unknown option: $1${NC}"
          show_help
          exit 1
          ;;
      esac
    done
    
    show_logs "$LINES"
    ;;
    
  status)
    show_status
    ;;
    
  help)
    show_help
    ;;
    
  *)
    echo -e "${RED}Unknown command: $COMMAND${NC}"
    show_help
    exit 1
    ;;
esac

exit 0
