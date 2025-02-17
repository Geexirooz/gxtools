#!/bin/bash

#sublist3r.py -e google,yahoo -d tomorrowland.com -o sublist3r.tomorrwoland.com.sub
#amass enum -d tomorrowland.com > amass.tomorrowland.com.sub
#echo tomorrowland.com | findomain -q --stdin > findomain.tomorrowland.com.sub
####APIs
###website => https://subdomainfinder.c99.nl/

# Define cache directory and file
TIME_OF_RUN=$(date +"%Y-%m-%d_%H-%M-%S")
TARGET_DOMAIN="$1"
GXENUM_DIR="$HOME/.gxenum"
CACHE_DIR="$HOME/.cache/gxenum"
CONFIG_DIR="$HOME/.config/gxenum"
STATS_FILE="$CONFIG_DIR/run_stats.json"
CACHE_NEW_SUBS="$CACHE_DIR/new_subs.txt"
SUBFINDER_OUTPUT="$GXENUM_DIR/$TARGET_DOMAIN.$TIME_OF_RUN.subfinder.json"
SUBFINDER="$HOME/go/bin/subfinder"
ALL_SUBS_FILE="$GXENUM_DIR/$TARGET_DOMAIN.subs"
FIRST_RUN=false
NOTIFY_DISCORD_NEWSUB_ID="new_subdomains"
JQ="/usr/bin/jq"
ANEW="$HOME/go/bin/anew"
NOTIFY="$HOME/go/bin/notify"

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
    /usr/bin/touch "$ALL_SUBS_FILE"
    FIRST_RUN=true
fi

# Remove previous new subs cache
if [[ -f "$CACHE_NEW_SUBS" ]]; then
    /usr/bin/rm -f $CACHE_NEW_SUBS
fi

# Get current date values
TODAY=$(date +%Y-%m-%d)
THIS_WEEK=$(date +%Y-%U)  # Year-Week format
THIS_MONTH=$(date +%Y-%m) # Year-Month format

# Initialize JSON file if not exists
if [[ ! -f "$STATS_FILE" ]]; then
    echo '{"daily": {}, "weekly": {}, "monthly": {}}' > "$STATS_FILE"
fi

# Read JSON data
DATA=$(/usr/bin/cat "$STATS_FILE")

# Update counts
DAILY_COUNT=$(echo "$DATA" | jq -r ".daily[\"$TODAY\"] // 0 | tonumber + 1")
WEEKLY_COUNT=$(echo "$DATA" | jq -r ".weekly[\"$THIS_WEEK\"] // 0 | tonumber + 1")
MONTHLY_COUNT=$(echo "$DATA" | jq -r ".monthly[\"$THIS_MONTH\"] // 0 | tonumber + 1")

# Update JSON file
UPDATED_DATA=$(echo "$DATA" | jq \
    ".daily[\"$TODAY\"] = $DAILY_COUNT | .weekly[\"$THIS_WEEK\"] = $WEEKLY_COUNT | .monthly[\"$THIS_MONTH\"] = $MONTHLY_COUNT")

echo "$UPDATED_DATA" > "$STATS_FILE"

# Actions based on run counts
#if [[ "$MONTHLY_COUNT" -gt 15500 ]]; then
#    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails,binaryedge,virustotal"
#elif [[ "$MONTHLY_COUNT" -gt 250 ]]; then
#    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails,binaryedge"
#elif [[ "$MONTHLY_COUNT" -gt 50 ]]; then
#    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails"
#elif [[ "$MONTHLY_COUNT" -gt 5 ]]; then
#    EXCLUDED_SOURCES="chaos,fullhunt"
#elif [[ "$WEEKLY_COUNT" -gt 1 ]]; then
#    EXCLUDED_SOURCES="chaos"
#fi

# Exclude sources more efficiently so it could consume the sources over the month instead of a single day
if [[ "$DAILY_COUNT" -gt 8 ]]; then
    EXCLUDED_SOURCES="chaos,fullhunt,bevigil,dnsdumpster,securitytrails,binaryedge"
elif [[ "$DAILY_COUNT" -gt 1 ]]; then
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

##############
#Run Subfinder
##############
echo $TIME_OF_RUN >> /var/tmp/gxenum.log
echo $SUBFINDER_CMD >> /var/tmp/gxenum.log
#$SUBFINDER_CMD

# Append new domains to the final sub files and store it in cache for Notify tool
cat $SUBFINDER_OUTPUT | $JQ -r '.host' | $ANEW $ALL_SUBS_FILE > $CACHE_NEW_SUBS

###########
#Run Notify
###########
if [[ "$FIRST_RUN" == false ]]; then
    $NOTIFY -silent -bulk -i $CACHE_NEW_SUBS -id $NOTIFY_DISCORD_NEWSUB_ID &>/dev/null
fi

