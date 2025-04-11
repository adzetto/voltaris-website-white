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

# Terminal width for progress bars
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
PROGRESS_WIDTH=$((TERM_WIDTH - 20))

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
# ADVANCED PROGRESS DISPLAY FUNCTIONS
# =======================

# Show fancy spinner with text
spinner() {
  local pid=$1
  local message=$2
  local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  local i=0
  local delay=0.1
  
  # Save cursor position and hide cursor
  tput sc
  tput civis
  
  echo -ne "${YELLOW}${BOLD}$message${NC} "
  
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % ${#spin} ))
    printf "${CYAN}%s${NC}" "${spin:$i:1}"
    sleep $delay
    printf "\b"
  done
  
  # Show cursor and restore position
  tput cnorm
  tput rc
  tput el
  echo -e "${GREEN}${BOLD}$message${NC} ${GREEN}✓${NC}"
}

# Progress bar for tracking completion
progress_bar() {
  local current=$1
  local total=$2
  local title=$3
  local percentage=$((current * 100 / total))
  local completed=$((current * PROGRESS_WIDTH / total))
  local remaining=$((PROGRESS_WIDTH - completed))
  
  # Clear line and move to start
  printf "\r"
  
  # Print title with fixed width
  printf "%-20s " "${title}"
  
  # Print progress bar
  printf "[${BLUE}"
  printf "%0.s█" $(seq 1 $completed)
  printf "${GRAY}"
  printf "%0.s▒" $(seq 1 $remaining)
  printf "${NC}] "
  
  # Print percentage
  printf "${BOLD}%3d%%${NC}" $percentage
}

# Create a multi-stage progress display
multi_stage_progress() {
  local stages=("$@")
  local total_stages=${#stages[@]}
  local current_stage=0
  
  # Print empty progress bars for all stages
  for stage in "${stages[@]}"; do
    current_stage=$((current_stage + 1))
    progress_bar 0 1 "$stage"
    echo
  done
  
  # Move cursor back up
  tput cuu $total_stages
  
  current_stage=0
  
  # Return the current position for later updates
  echo $current_stage
}

# Update a stage in the multi-stage display
update_stage_progress() {
  local position=$1
  local stage_num=$2
  local progress=$3
  local total=$4
  local stages=("${@:5}")
  
  # Move to the correct position
  tput cuu $((${#stages[@]} - stage_num))
  
  # Update the specific stage
  progress_bar $progress $total "${stages[$stage_num-1]}"
  
  # Move back down
  tput cud $((${#stages[@]} - stage_num))
}

# Complete a stage in the multi-stage display
complete_stage() {
  local position=$1
  local stage_num=$2
  local stages=("${@:3}")
  
  # Move to the correct position
  tput cuu $((${#stages[@]} - stage_num))
  
  # Update the specific stage to 100%
  progress_bar 1 1 "${stages[$stage_num-1]}"
  
  # Move back down
  tput cud $((${#stages[@]} - stage_num))
}

# Animated task completion
animated_task() {
  local message=$1
  local delay=0.02
  local i=0
  
  # Print message with trailing dots animation
  printf "${YELLOW}${BOLD}%s${NC}" "$message"
  
  for ((i=0; i<3; i++)); do
    for ((j=0; j<4; j++)); do
      printf "${CYAN}%s${NC}" "."
      sleep $delay
    done
    printf "\b\b\b\b    \b\b\b\b"
    sleep $delay
  done
  
  printf "\r${GREEN}${BOLD}%s${NC} ${GREEN}✓${NC}\n" "$message"
}

# Display a boxed summary
summary_box() {
  local title=$1
  local width=$((TERM_WIDTH - 4))
  local title_len=${#title}
  local padding=$(( (width - title_len) / 2 ))
  
  # Print top border
  printf "${BLUE}╭"
  printf "─%.0s" $(seq 1 $width)
  printf "╮${NC}\n"
  
  # Print title row
  printf "${BLUE}│${NC}${BOLD}"
  printf " %.0s" $(seq 1 $padding)
  printf "%s" "$title"
  printf " %.0s" $(seq 1 $((width - title_len - padding)))
  printf "${NC}${BLUE}│${NC}\n"
  
  # Print separator
  printf "${BLUE}├"
  printf "─%.0s" $(seq 1 $width)
  printf "┤${NC}\n"
  
  echo
}

# Close a summary box
close_summary_box() {
  local width=$((TERM_WIDTH - 4))
  
  echo
  
  # Print bottom border
  printf "${BLUE}╰"
  printf "─%.0s" $(seq 1 $width)
  printf "╯${NC}\n"
}

# Display a titled section
section_title() {
  local title=$1
  local width=$((TERM_WIDTH - 4))
  
  echo
  printf "${CYAN}${BOLD}┌─"
  printf "─%.0s" $(seq 1 $((width - ${#title} - 5)))
  printf "┐${NC}\n"
  
  printf "${CYAN}${BOLD}│ %s ${NC}\n" "$title"
  
  printf "${CYAN}${BOLD}└"
  printf "─%.0s" $(seq 1 $((width - 2)))
  printf "┘${NC}\n"
}

# =======================
# UTILITY FUNCTIONS
# =======================

# Initialize the environment
initialize() {
  section_title "Initializing Environment"
  
  # Create backup directory
  if [ ! -d "$BACKUP_DIR" ]; then
    animated_task "Creating backup directory"
    mkdir -p "$BACKUP_DIR"
  else
    echo -e "${GREEN}✓${NC} Backup directory exists"
  fi
  
  # Create logs directory
  if [ ! -d "$LOGS_DIR" ]; then
    animated_task "Creating logs directory"
    mkdir -p "$LOGS_DIR"
  else
    echo -e "${GREEN}✓${NC} Logs directory exists"
  fi
  
  # Create/check config file
  if [ ! -f "$CONFIG_FILE" ]; then
    animated_task "Creating configuration file"
    echo '{
      "branch": "main",
      "last_deployment": null,
      "total_deployments": 0,
      "backups": []
    }' > "$CONFIG_FILE"
  else
    echo -e "${GREEN}✓${NC} Configuration file exists"
  fi
  
  echo -e "\n${GREEN}${BOLD}Environment initialized successfully!${NC}\n"
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
  section_title "Checking Dependencies"
  
  local missing=0
  local deps=("git" "npm" "jq")
  local total=${#deps[@]}
  local current=0
  
  # Initialize progress bars
  for dep in "${deps[@]}"; do
    current=$((current + 1))
    progress_bar 0 1 "Checking $dep"
    echo
  done
  
  # Move cursor back up to start of progress display
  tput cuu $total
  
  # Check each dependency with progress
  current=0
  for dep in "${deps[@]}"; do
    current=$((current + 1))
    
    for i in {1..5}; do
      progress_bar $i 5 "Checking $dep"
      sleep 0.05
    done
    
    if command_exists "$dep"; then
      echo -e "\r${GREEN}✓${NC} $dep detected ${GRAY}$(which $dep)${NC}${CLEAR_LINE}"
    else
      echo -e "\r${RED}✗${NC} $dep not found${CLEAR_LINE}"
      missing=1
      
      if [ "$dep" = "jq" ]; then
        echo -e "${YELLOW}  Please install jq: https://stedolan.github.io/jq/download/${NC}"
      fi
    fi
  done
  
  if [ $missing -eq 1 ]; then
    echo -e "\n${RED}${BOLD}Missing dependencies. Please install them before proceeding.${NC}"
    exit 1
  fi
  
  echo -e "\n${GREEN}${BOLD}All dependencies satisfied!${NC}"
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
  
  section_title "Creating backup $backup_id"
  
  # Create backup directory
  mkdir -p "$backup_path"
  
  # Setup progress tracking
  local total_files=$((${#BACKUP_FILES[@]} + 2)) # +2 for build dir and git status
  local current_file=0
  
  # Copy critical files with progress
  for file in "${BACKUP_FILES[@]}"; do
    current_file=$((current_file + 1))
    
    if [ -f "$file" ]; then
      cp "$file" "$backup_path/"
      progress_bar $current_file $total_files "Backing up files"
      echo -e "\r${GREEN}✓${NC} Backed up $file${CLEAR_LINE}"
    else
      progress_bar $current_file $total_files "Backing up files"
      echo -e "\r${YELLOW}⚠${NC} File $file not found, skipping${CLEAR_LINE}"
    fi
    
    sleep 0.05 # slight delay for visual effect
  done
  
  # Create a snapshot of the build directory if it exists
  current_file=$((current_file + 1))
  progress_bar $current_file $total_files "Backing up files"
  
  if [ -d "build" ]; then
    animated_task "Backing up build directory"
    mkdir -p "$backup_path/build"
    cp -r build/* "$backup_path/build/"
  else
    echo -e "${YELLOW}⚠${NC} Build directory not found, skipping"
  fi
  
  # Store git status
  current_file=$((current_file + 1))
  progress_bar $current_file $total_files "Backing up files"
  
  git log -1 --format="%H%n%an%n%ad%n%s" > "$backup_path/git-status.txt"
  echo -e "${GREEN}✓${NC} Saved git commit information"
  
  # Update config with backup info
  if [ -z "$description" ]; then
    description="Automated backup"
  fi
  
  animated_task "Updating backup registry"
  add_backup_entry "$backup_id" "$backup_path" "$description"
  
  # Log the event
  log_event "BACKUP" "Created backup $backup_id: $description"
  
  summary_box "Backup Summary"
  echo -e "  ${BOLD}Backup ID:${NC} ${CYAN}$backup_id${NC}"
  echo -e "  ${BOLD}Description:${NC} ${CYAN}$description${NC}"
  echo -e "  ${BOLD}Location:${NC} ${CYAN}$backup_path${NC}"
  echo -e "  ${BOLD}Files backed up:${NC} ${CYAN}$current_file${NC}"
  echo -e "  ${BOLD}Time:${NC} ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
  close_summary_box
  
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
  
  section_title "Restoring from backup $backup_id"
  
  echo -e "${YELLOW}${BOLD}Warning: This will overwrite your current configuration files!${NC}"
  read -p "Are you sure you want to continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restoration cancelled.${NC}"
    return 1
  fi
  
  # First create a backup of the current state
  animated_task "Creating safety backup before restore"
  create_backup "Pre-restore safety backup"
  
  # Setup progress tracking
  local total_files=${#BACKUP_FILES[@]}
  local current_file=0
  
  # Restore files
  for file in "${BACKUP_FILES[@]}"; do
    current_file=$((current_file + 1))
    progress_bar $current_file $total_files "Restoring files"
    
    if [ -f "$backup_path/$file" ]; then
      cp "$backup_path/$file" "./$file"
      echo -e "\r${GREEN}✓${NC} Restored $file${CLEAR_LINE}"
    else
      echo -e "\r${YELLOW}⚠${NC} File $file not found in backup, skipping${CLEAR_LINE}"
    fi
    
    sleep 0.05 # slight delay for visual effect
  done
  
  # Restore build if it exists in the backup
  if [ -d "$backup_path/build" ]; then
    animated_task "Restoring build directory"
    rm -rf ./build
    mkdir -p ./build
    cp -r "$backup_path/build"/* ./build/
  else
    echo -e "${YELLOW}⚠${NC} Build directory not found in backup, skipping"
  fi
  
  # Log the event
  log_event "RESTORE" "Restored from backup $backup_id"
  
  summary_box "Restoration Complete"
  echo -e "  ${BOLD}Restored from:${NC} ${CYAN}$backup_id${NC}"
  echo -e "  ${BOLD}Files restored:${NC} ${CYAN}$current_file${NC}"
  echo -e "  ${BOLD}Time:${NC} ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "  ${YELLOW}Note: This only restored configuration files, not your source code.${NC}"
  close_summary_box
  
  return 0
}

# List all backups
list_backups() {
  section_title "Available Backups"
  
  # Check if we have any backups
  local backup_count=$(jq '.backups | length' "$CONFIG_FILE")
  if [ "$backup_count" -eq 0 ]; then
    echo -e "${YELLOW}No backups found.${NC}"
    return 0
  fi
  
  # Print header
  printf "${CYAN}%-20s │ %-25s │ %-40s${NC}\n" "BACKUP ID" "DATE" "DESCRIPTION"
  echo "────────────────────┼───────────────────────┼──────────────────────────────────────────"
  
  # Print each backup with loading animation
  local current=0
  jq -r '.backups[] | "\(.id) \(.date) \(.description)"' "$CONFIG_FILE" | \
  while read -r id date description; do
    current=$((current + 1))
    progress_bar $current $backup_count "Loading backups"
    printf "\r${GRAY}%-20s │ %-25s │ %-40s${NC}\n" "$id" "$date" "$description"
    
    # Add slight delay for visual loading effect
    if [ $current -lt $backup_count ]; then
      sleep 0.05
    fi
  done
  
  echo "────────────────────┴───────────────────────┴──────────────────────────────────────────"
  echo -e "${GRAY}To restore a backup: ${CYAN}./voltaris-cli.sh restore <BACKUP_ID>${NC}"
  
  return 0
}

# Show deployment history
show_history() {
  section_title "Deployment History"
  
  if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR")" ]; then
    echo -e "${YELLOW}No deployment logs found.${NC}"
    return 0
  fi
  
  # Get the log entries
  local log_entries=$(grep -h "\[DEPLOY\]" "$LOGS_DIR"/*.log | tail -n 10)
  local log_count=$(echo "$log_entries" | wc -l)
  
  # Print header
  echo -e "${CYAN}${BOLD}Recent Deployments${NC}"
  echo "───────────────────────────────────────────────────────────────────────────────"
  
  # Show loading animation
  if [ $log_count -gt 0 ]; then
    local current=0
    echo "$log_entries" | while read -r line; do
      current=$((current + 1))
      progress_bar $current $log_count "Loading history"
      echo -e "\r${GRAY}$line${NC}"
      
      # Add slight delay for visual loading effect
      if [ $current -lt $log_count ]; then
        sleep 0.05
      fi
    done
  else
    echo -e "${YELLOW}No deployments found in logs.${NC}"
  fi
  
  echo "───────────────────────────────────────────────────────────────────────────────"
  
  # Show total stats with animation
  animated_task "Loading deployment statistics"
  
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
  
  section_title "Starting Deployment Process"
  
  # Check git status first
  check_git_status
  local git_status=$?
  
  # Create backup before deploying (unless skipped)
  if [ "$skip_backup" != "true" ]; then
    create_backup "Pre-deployment backup"
  else
    echo -e "${YELLOW}Skipping backup as requested.${NC}"
  fi
  
  # Setup deployment stages
  local stages=("Building" "Git Add" "Committing" "Pushing" "Finalizing")
  local current_stage=1
  
  # Initialize multi-stage display
  echo
  for stage in "${stages[@]}"; do
    progress_bar 0 1 "$stage"
    echo
  done
  echo
  
  # Move back to start of progress display
  tput cuu $((${#stages[@]} + 1))
  
  # Build the project (unless skipped)
  if [ "$skip_build" != "true" ]; then
    # Start the build process
    npm run build > /tmp/voltaris-build.log 2>&1 &
    build_pid=$!
    
    # Show animated progress while building
    local i=0
    while kill -0 $build_pid 2>/dev/null; do
      i=$(( (i+10) % 100 ))
      progress_bar $i 100 "${stages[0]}"
      sleep 0.1
    done
    
    # Check if build succeeded
    if wait $build_pid; then
      complete_stage $position 1 "${stages[@]}"
      echo -e "\n${GREEN}✓${NC} Build successful"
    else
      progress_bar 100 100 "${stages[0]}"
      echo -e "\n${RED}✗${NC} Build failed"
      echo -e "${YELLOW}Build log:${NC}"
      cat /tmp/voltaris-build.log
      log_event "DEPLOY" "Failed: Build error"
      return 1
    fi
  else
    # Skip build but mark as complete
    complete_stage $position 1 "${stages[@]}"
    echo -e "\n${YELLOW}⚠${NC} Build skipped as requested"
  fi
  
  # Add all changes to git
  echo -e "\n${YELLOW}Adding all changes to git...${NC}"
  for i in {1..10}; do
    progress_bar $((i*10)) 100 "${stages[1]}"
    sleep 0.05
  done
  git add .
  complete_stage $position 2 "${stages[@]}"
  
  # Get commit message if not provided
  if [ -z "$commit_message" ]; then
    tput cud 3 # Move down to make space for input
    echo -e "${YELLOW}Please enter a commit message:${NC}"
    read -p "> " commit_message
    tput cuu 3 # Move back up
    
    if [ -z "$commit_message" ]; then
      commit_message="Update website content $(date '+%Y-%m-%d %H:%M:%S')"
      echo -e "${YELLOW}No message provided. Using default: ${NC}${commit_message}"
    fi
  fi
  
  # Commit changes with animation
  echo -e "\n${YELLOW}Committing changes...${NC}"
  for i in {1..10}; do
    progress_bar $((i*10)) 100 "${stages[2]}"
    sleep 0.05
  done
  git commit -m "$commit_message"
  complete_stage $position 3 "${stages[@]}"
  
  # Push to GitHub with animation
  echo -e "\n${YELLOW}Pushing to GitHub...${NC}"
  local branch=$(jq -r '.branch' "$CONFIG_FILE")
  if [ "$branch" == "null" ]; then
    branch="$DEFAULT_BRANCH"
  fi
  
  # Start real push in background
  git push origin $branch > /tmp/voltaris-push.log 2>&1 &
  push_pid=$!
  
  # Show animated progress while pushing
  local i=0
  while kill -0 $push_pid 2>/dev/null; do
    i=$(( (i+5) % 100 ))
    progress_bar $i 100 "${stages[3]}"
    sleep 0.1
  done
  
  # Check if push succeeded
  if wait $push_pid; then
    complete_stage $position 4 "${stages[@]}"
    echo -e "\n${GREEN}✓${NC} Push successful"
  else
    progress_bar 100 100 "${stages[3]}"
    echo -e "\n${RED}✗${NC} Push failed"
    echo -e "${YELLOW}Push log:${NC}"
    cat /tmp/voltaris-push.log
    log_event "DEPLOY" "Failed: Git push error"
    return 1
  fi
  
  # Finalizing
  echo -e "\n${YELLOW}Finalizing deployment...${NC}"
  for i in {1..10}; do
    progress_bar $((i*10)) 100 "${stages[4]}"
    sleep 0.05
  done
  
  # Update deployment tracking
  local deployment_date=$(date '+%Y-%m-%d %H:%M:%S')
  update_config "last_deployment" "\"$deployment_date\""
  
  local total_deployments=$(jq '.total_deployments' "$CONFIG_FILE")
  total_deployments=$((total_deployments + 1))
  update_config "total_deployments" "$total_deployments"
  
  # Log the event
  log_event "DEPLOY" "Success: $commit_message"
  complete_stage $position 5 "${stages[@]}"
  
  # Deployment complete
  summary_box "Deployment Complete!"
  echo -e "  ${BOLD}Commit message:${NC} ${CYAN}$commit_message${NC}"
  echo -e "  ${BOLD}Branch:${NC} ${CYAN}$branch${NC}"
  echo -e "  ${BOLD}Deployment time:${NC} ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "  ${BOLD}Total deployments:${NC} ${CYAN}$total_deployments${NC}"
  echo -e ""
  echo -e "  ${YELLOW}Your changes have been pushed to GitHub.${NC}"
  echo -e "  ${YELLOW}GitHub Actions will now deploy your website to GitHub Pages.${NC}"
  echo -e "  ${YELLOW}You can check the progress in the 'Actions' tab of your GitHub repository.${NC}"
  close_summary_box
  
  return 0
}

# Show logs
show_logs() {
  local lines=$1
  
  if [ -z "$lines" ]; then
    lines=20
  fi
  
  section_title "Recent Logs"
  
  if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR")" ]; then
    echo -e "${YELLOW}No logs found.${NC}"
    return 0
  fi
  
  # Find the most recent log file
  local latest_log=$(ls -t "$LOGS_DIR"/*.log | head -1)
  
  # Count total log lines
  local total_lines=$(wc -l < "$latest_log")
  if [ "$total_lines" -lt "$lines" ]; then
    lines=$total_lines
  fi
  
  echo -e "${CYAN}Showing last $lines entries from ${latest_log}${NC}"
  echo "───────────────────────────────────────────────────────────────────────────────"
  
  # Display the logs with animated loading and colors based on event type
  local current=0
  tail -n "$lines" "$latest_log" | while read -r line; do
    current=$((current + 1))
    progress_bar $current $lines "Loading logs"
    
    if [[ "$line" == *"[DEPLOY]"* ]]; then
      echo -e "\r${CYAN}$line${NC}"
    elif [[ "$line" == *"[BACKUP]"* ]]; then
      echo -e "\r${GREEN}$line${NC}"
    elif [[ "$line" == *"[RESTORE]"* ]]; then
      echo -e "\r${PURPLE}$line${NC}"
    elif [[ "$line" == *"[ERROR]"* ]]; then
      echo -e "\r${RED}$line${NC}"
    else
      echo -e "\r${GRAY}$line${NC}"
    fi
    
    # Slight delay for visual loading effect
    if [ $current -lt $lines ]; then
      sleep 0.02
    fi
  done
  
  echo "───────────────────────────────────────────────────────────────────────────────"
  
  return 0
}

# Display help
show_help() {
  clear
  echo -e "${BLUE}${BOLD}"
  echo -e "██╗   ██╗ ██████╗ ██╗  ████████╗ █████╗ ██████╗ ██╗███████╗"
  echo -e "██║   ██║██╔═══██╗██║  ╚══██╔══╝██╔══██╗██╔══██╗██║██╔════╝"
  echo -e "██║   ██║██║   ██║██║     ██║   ███████║██████╔╝██║███████╗"
  echo -e "╚██╗ ██╔╝██║   ██║██║     ██║   ██╔══██║██╔══██╗██║╚════██║"
  echo -e " ╚████╔╝ ╚██████╔╝███████╗██║   ██║  ██║██║  ██║██║███████║"
  echo -e "  ╚═══╝   ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝"
  echo -e "${NC}"
  echo -e "${CYAN}${BOLD}CLI Deployment Tool${NC} ${GRAY}v1.0.0${NC}\n"
  
  echo -e "${BLUE}${BOLD}USAGE:${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh ${CYAN}<command>${NC} ${YELLOW}[options]${NC}\n"
  
  echo -e "${BLUE}${BOLD}COMMANDS:${NC}"
  echo -e "  ${GREEN}deploy${NC}    Deploy the website to GitHub Pages"
  echo -e "  ${GREEN}backup${NC}    Create a backup of critical files"
  echo -e "  ${GREEN}restore${NC}   Restore from a backup"
  echo -e "  ${GREEN}backups${NC}   List all available backups"
  echo -e "  ${GREEN}history${NC}   Show deployment history"
  echo -e "  ${GREEN}logs${NC}      Show recent logs"
  echo -e "  ${GREEN}status${NC}    Show current project status"
  echo -e "  ${GREEN}help${NC}      Show this help message\n"
  
  echo -e "${BLUE}${BOLD}OPTIONS:${NC}"
  echo -e "  ${GREEN}deploy${NC}"
  echo -e "    ${YELLOW}-m, --message${NC}    Specify commit message"
  echo -e "    ${YELLOW}-s, --skip-build${NC} Skip the build process"
  echo -e "    ${YELLOW}-n, --no-backup${NC}  Skip creating a backup\n"
  
  echo -e "  ${GREEN}backup${NC}"
  echo -e "    ${YELLOW}-d, --description${NC} Specify backup description\n"
  
  echo -e "  ${GREEN}restore${NC}"
  echo -e "    ${YELLOW}<backup-id>${NC}       ID of the backup to restore\n"
  
  echo -e "  ${GREEN}logs${NC}"
  echo -e "    ${YELLOW}-n, --lines${NC}       Number of log lines to show (default: 20)\n"
  
  echo -e "${BLUE}${BOLD}EXAMPLES:${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh deploy -m \"Updated home page\"${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh backup -d \"Before major changes\"${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh restore 20230415-123045${NC}"
  echo -e "  ${GRAY}./voltaris-cli.sh logs -n 50${NC}\n"
  
  return 0
}

# Show status
show_status() {
  section_title "Voltaris Website Status"
  
  # Git status with loading animation
  echo -e "\n${CYAN}${BOLD}Git Status:${NC}"
  animated_task "Loading git information"
  
  git_branch=$(git branch --show-current)
  git_commit=$(git rev-parse --short HEAD)
  git_message=$(git log -1 --pretty=%B)
  
  echo -e "${GRAY}Branch:${NC} ${GREEN}$git_branch${NC}"
  echo -e "${GRAY}Commit:${NC} ${GREEN}$git_commit${NC}"
  echo -e "${GRAY}Message:${NC} ${GREEN}$git_message${NC}"
  
  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}You have uncommitted changes:${NC}"
    git status -s | while read -r line; do
      # Color different git status codes
      if [[ "$line" == A* ]]; then
        echo -e "${GREEN}$line${NC}" # Added
      elif [[ "$line" == M* ]]; then
        echo -e "${BLUE}$line${NC}" # Modified
      elif [[ "$line" == D* ]]; then
        echo -e "${RED}$line${NC}" # Deleted
      elif [[ "$line" == R* ]]; then
        echo -e "${PURPLE}$line${NC}" # Renamed
      elif [[ "$line" == \?\?* ]]; then
        echo -e "${GRAY}$line${NC}" # Untracked
      else
        echo -e "$line"
      fi
    done
  else
    echo -e "${GREEN}Working directory clean.${NC}"
  fi
  
  # Project stats with loading animation
  echo -e "\n${CYAN}${BOLD}Project Stats:${NC}"
  animated_task "Loading project statistics"
  
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
  
  # Check npm dependencies with progress bar
  echo -e "\n${CYAN}${BOLD}Dependencies:${NC}"
  animated_task "Checking npm dependencies"
  
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
    
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Deploy
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
    
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Create backup
    create_backup "$DESCRIPTION"
    ;;
    
  restore)
    BACKUP_ID=$1
    
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Restore backup
    restore_backup "$BACKUP_ID"
    ;;
    
  backups)
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # List backups
    list_backups
    ;;
    
  history)
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Show history
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
    
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Show logs
    show_logs "$LINES"
    ;;
    
  status)
    # Clear screen for better UI
    clear
    
    # Check dependencies
    check_dependencies
    
    # Initialize environment
    initialize
    
    # Show status
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
