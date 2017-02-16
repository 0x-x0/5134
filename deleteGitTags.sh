#!/bin/bash
CURR_REL_TAG='v1.0.0-alpha.4'
CURR_REL_TAG_TIME=$(git for-each-ref --format="%(refname:short) %(authordate:raw)" refs/tags/* | grep $CURR_REL_TAG | awk '{print $2}')
git for-each-ref --format="%(refname:short) %(authordate:raw)" refs/tags/* | while read line
do
	CURR_TAG=$(echo $line | awk '{print $1}')
	CURR_TAG_TIMESTAMP=$(echo $line | awk '{print $2}')
	if [[ $CURR_TAG_TIMESTAMP != "" && $CURR_TAG_TIMESTAMP != null && $CURR_TAG_TIMESTAMP -lt $CURR_REL_TAG_TIME ]] ; then
		echo "$CURR_TAG was pushed before $CURR_REL_TAG"
	fi
done