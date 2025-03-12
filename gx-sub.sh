#!/bin/bash

#sublist3r.py -e google,yahoo -d tomorrowland.com -o sublist3r.tomorrwoland.com.sub
#amass enum -d tomorrowland.com > amass.tomorrowland.com.sub
#echo tomorrowland.com | findomain -q --stdin > findomain.tomorrowland.com.sub
####APIs
###website => https://subdomainfinder.c99.nl/

##################
# Define variables
##################
TIME_OF_RUN=$(date +"%Y-%m-%d_%H-%M-%S")
TARGET_DOMAIN="$1"

# Define gxsub directories
GXENUM_DIR="$HOME/.gxenum"
CACHE_DIR="$HOME/.cache/gxenum"
CONFIG_DIR="$HOME/.config/gxenum"

# Define stats file
STATS_FILE="$CONFIG_DIR/run_stats.json"

# Define subfinder files
SUBFINDER_OUTPUT="$GXENUM_DIR/$TARGET_DOMAIN.$TIME_OF_RUN.subfinder.json"
SUBFINDER="$HOME/go/bin/subfinder"

# Define subdomains files
CACHE_NEW_ACTIVE_SUBS="$CACHE_DIR/new_active_subs.$TARGET_DOMAIN.$TIME_OF_RUN.txt"
ALL_SUBS_FILE="$GXENUM_DIR/$TARGET_DOMAIN.subs"
ALL_ACTIVE_SUBS="$GXENUM_DIR/$TARGET_DOMAIN.active.subs"

# Define httpx related files
HTTPX_OUTPUT="$GXENUM_DIR/$TARGET_DOMAIN.$TIME_OF_RUN.httpx"
HTTPX_FINAL_OUTPUT="$GXENUM_DIR/$TARGET_DOMAIN.httpx"
CACHE_NEW_HTTPX="$CACHE_DIR/new_httpx.$TARGET_DOMAIN.$TIME_OF_RUN.httpx"
HTTPX_PORTS="80,81,443,591,2082,2087,2095,2096,3000,5000,8000,8001,8008,8080,8081,8083,8088,8090,8091,8443,8834,8880,8888"

# Define dnsx resolvers file
RESOLVERS_FILES="$GXENUM_DIR/resolvers.txt"

# Discord IDs
NOTIFY_DISCORD_NEW_SUB_ID="new_subdomains"
NOTIFY_DISCORD_NEW_HTTPX_ID="new_httpx"

# Tools absolute paths
JQ="/usr/bin/jq"
ANEW="$HOME/go/bin/anew"
NOTIFY="$HOME/go/bin/notify"
HTTPX="$HOME/go/bin/httpx"
DNSX="$HOME/go/bin/dnsx"

#################
# Local variables
#################
FIRST_RUN=false

# Get current date values
TODAY=$(date +%Y-%m-%d)
THIS_WEEK=$(date +%Y-%U)
THIS_MONTH=$(date +%Y-%m)

###########
# Functions
###########

# Function to remove an empty file
remove_empty_files() {
  for file in "$@"; do

  # Check if file exists and is empty
    if [[ -e "$file" && ! -s "$file" ]]; then
      rm "$file"
    fi
  done
}

#######################################
# Create the required files/directories
#######################################

# Ensure a domain was provided
if [[ -z "$TARGET_DOMAIN" ]]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Ensure gxenum directory exists
if [[ ! -d "$GXENUM_DIR" ]]; then
    /usr/bin/mkdir -p "$GXENUM_DIR"
fi

# Ensure cache directory exists
if [[ ! -d "$CACHE_DIR" ]]; then
    /usr/bin/mkdir -p "$CACHE_DIR"
fi

# Ensure config directory exists
if [[ ! -d "$CONFIG_DIR" ]]; then
    /usr/bin/mkdir -p "$CONFIG_DIR"
fi

# Ensure the final subs file exists -> if not, it is the first run
if [[ ! -f "$ALL_SUBS_FILE" ]]; then
    FIRST_RUN=true
fi

############
# stats file
############

# Initialize stats file if not exists
if [[ ! -f "$STATS_FILE" ]]; then
    echo '{"daily": {}, "weekly": {}, "monthly": {}}' > "$STATS_FILE"
fi

# Read stats data
DATA=$(/usr/bin/cat "$STATS_FILE")

# Update counts
DAILY_COUNT=$(echo "$DATA" | jq -r ".daily[\"$TODAY\"] // 0 | tonumber + 1")
WEEKLY_COUNT=$(echo "$DATA" | jq -r ".weekly[\"$THIS_WEEK\"] // 0 | tonumber + 1")
MONTHLY_COUNT=$(echo "$DATA" | jq -r ".monthly[\"$THIS_MONTH\"] // 0 | tonumber + 1")

# Update stats file
UPDATED_DATA=$(echo "$DATA" | jq \
    ".daily[\"$TODAY\"] = $DAILY_COUNT | .weekly[\"$THIS_WEEK\"] = $WEEKLY_COUNT | .monthly[\"$THIS_MONTH\"] = $MONTHLY_COUNT")

echo "$UPDATED_DATA" > "$STATS_FILE"

###############
# Run Subfinder
###############

# Exclude sources more efficiently so it could consume the sources over the month instead of a single day
if [[ "$DAILY_COUNT" -gt 8 || "$MONTHLY_COUNT" -gt 250 ]]; then
    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails,binaryedge"
elif [[ "$DAILY_COUNT" -gt 1 || "$MONTHLY_COUNT" -gt 50 ]]; then
    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails"
elif [[ "$WEEKLY_COUNT" -gt 1 ]]; then
    EXCLUDED_SOURCES="chaos,fullhunt"
fi

# Run subfinder
if [[ -n "$EXCLUDED_SOURCES" ]]; then
    SUBFINDER_CMD="$SUBFINDER -o $SUBFINDER_OUTPUT -oJ -cs -silent -nc -all -es $EXCLUDED_SOURCES -d $TARGET_DOMAIN"
else
    SUBFINDER_CMD="$SUBFINDER -o $SUBFINDER_OUTPUT -oJ -cs -silent -nc -all -d $TARGET_DOMAIN"
fi

#######Delete the following 2 lines
echo $TIME_OF_RUN >> /var/tmp/gxenum.log
echo $SUBFINDER_CMD >> /var/tmp/gxenum.log
$SUBFINDER_CMD

###################################################
# Find new subdomains and accumulate all subdomains
###################################################

# Append new domains to the final sub files and store it in cache for Notify tool
/usr/bin/cat $SUBFINDER_OUTPUT | $JQ -r '.host' | $ANEW -q $ALL_SUBS_FILE

# Find active subdomains and extract new active subdomains (Run DNS queries 3 times for reliability)

# If it's the first time -> resolve all domains
if [[ "$FIRST_RUN" == true ]]; then
  for i in {1..3}; do
    /usr/bin/cat $ALL_SUBS_FILE | $DNSX -all -silent -r $RESOLVERS_FILES | /usr/bin/cut -d' ' -f1 | $ANEW -q $ALL_ACTIVE_SUBS
  done

# If not the first time -> just try to resolve previously inactive domains
else
  for i in {1..3}; do
    /usr/bin/cat $ALL_SUBS_FILE | $ANEW -d $ALL_ACTIVE_SUBS |$DNSX -all -silent -r $RESOLVERS_FILES | /usr/bin/cut -d' ' -f1 | $ANEW $CACHE_NEW_ACTIVE_SUBS | $ANEW -q $ALL_ACTIVE_SUBS
  done
fi

###################################
# Run Notify for new active domains
###################################

# Check if it's the first time to avoid spam :D
if [[ "$FIRST_RUN" == false ]]; then
    $NOTIFY -silent -bulk -i $CACHE_NEW_ACTIVE_SUBS -id $NOTIFY_DISCORD_NEW_SUB_ID &>/dev/null
fi

######
#httpx
######

# Run httpx against live hosts
$HTTPX -l $ALL_ACTIVE_SUBS -silent -sc -no-color -p $HTTPX_PORTS -o $HTTPX_OUTPUT

# Extract new URLs
/usr/bin/cat $HTTPX_OUTPUT | $ANEW $HTTPX_FINAL_OUTPUT > $CACHE_NEW_HTTPX

#########################
# Run Notify for new URLs
#########################

# Check if it's the first time to avoid spam :D
if [[ "$FIRST_RUN" == false ]]; then
    $NOTIFY -silent -bulk -i $CACHE_NEW_HTTPX -id $NOTIFY_DISCORD_NEW_HTTPX_ID &>/dev/null
fi

##########
# Clean up
##########

# Remove cache files
remove_empty_files "$CACHE_NEW_ACTIVE_SUBS" "$CACHE_NEW_HTTPX"
