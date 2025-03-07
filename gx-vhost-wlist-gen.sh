#!/bin/bash

# Input
DOMAIN="$1"
OUTPUT_DIR="$2"

# gxsub.sh script stuff
GXENUM_DIR="$HOME/.gxenum"
SUBS_FILE="$GXENUM_DIR/$DOMAIN.subs"

# Files create by this script
ALL_VHOSTS_FILE="$OUTPUT_DIR/vhosts-all.txt"
PURE_VHOSTS_FILE="$OUTPUT_DIR/vhosts-pure.txt"
TEMP_CACHE="/tmp/fhvvuBDebdfEJdfvbfDEbfb.gx"

# Tools absolute paths
ANEW="$HOME/go/bin/anew"

if [[ ! -d "$OUTPUT_DIR" ]]; then
    /usr/bin/mkdir -p "$OUTPUT_DIR"
fi

/usr/bin/cat $SUBS_FILE | sed "s/.$DOMAIN//g" | $ANEW $ALL_VHOSTS_FILE | tr '.' '\n' | $ANEW $PURE_VHOSTS_FILE > $TEMP_CACHE
/usr/bin/cat $TEMP_CACHE | tr '-' '\n' | $ANEW -q $PURE_VHOSTS_FILE 
/usr/bin/cat $PURE_VHOSTS_FILE | $ANEW -q $ALL_VHOSTS_FILE
/usr/bin/rm $TEMP_CACHE
