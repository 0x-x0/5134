#!/bin/bash -e

export RES_PARAMS="teamParams"

export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"
export GITHUB_TOKEN=$(eval echo "$"$RES_PARAMS_STR"_TOKEN")
export ORG_NAME=$(eval echo "$"$RES_PARAMS_STR"_ORG_NAME")
export TEAM_ID=$(eval echo "$"$RES_PARAMS_STR"_TEAM_ID")
export TEAM_NAME=$(eval echo "$"$RES_PARAMS_STR"_TEAM_NAME")
export GITHUB_API_URL=$(eval echo "$"$RES_PARAMS_STR"_GITHUB_API_URL")

set_context() {
  echo "ORG_NAME=$ORG_NAME"
  echo "TEAM_NAME=$TEAM_NAME"
  echo "TEAM_ID=$TEAM_ID"
  echo "GITHUB_API_URL=$GITHUB_API_URL"
}

check_jq() {
  {
    type jq &> /dev/null && echo "jq is already installed"
  } || {
    echo "Installing 'jq'"
    echo "----------------------------------------------"
    apt-get install -y jq
  }
}

get_team_repos() {
  if [ $TEAM_ID != "" ] || [ $TEAM_ID != null ]; then
    echo "Getting team repositories for $TEAM_NAME"
    echo "----------------------------------------------"
    pageNo=1
    while [1], do
      local url="$GITHUB_API_URL/teams/$TEAM_ID/repos?page=$pageNo"
      local res=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $GITHUB_TOKEN" $url)
      length=$(echo $res |  jq '. | length')
      if [ $? -eq 0 ]; then
        TEAM_REPOS+=$(echo $res |  jq -r ".[] | .name")
        echo "Found $length reposotries for $TEAM_NAME team"
        echo "----------------------------------------------"
        echo "$TEAM_REPOS"
        echo "----------------------------------------------"
      fi
      pageNo=$((pageNo+1))
    done
  fi
}

change_permissions() {
  if [ -n "$TEAM_REPOS" ]; then
    echo "Changing permissions for $TEAM_NAME"
    echo "----------------------------------------------"

    local permission="$1"
    local data="{\"permission\": \"$permission\"}"
    for repo_name in $TEAM_REPOS; do
      url="$GITHUB_API_URL/teams/$TEAM_ID/repos/$ORG_NAME/$repo_name"
      echo $url
      #check if this repo is managed by the team
      local responseCode=$(curl --write-out %{http_code} --silent -X GET -H "Accept: application/json" -H "Authorization: token $GITHUB_TOKEN" $url)
      if [ $responseCode -eq 204 ]; then
        local res=$(curl --write-out %{http_code} --silent -X PUT -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.repository+json" -H "Authorization: token $GITHUB_TOKEN" $url -d "$data")
        if [ $res -eq 204 ]; then
          echo "Permission updated to $permission for $repo_name"
          echo "----------------------------------------------"
        else
          echo "Update $permission permission failed for $repo_name"
          echo "----------------------------------------------"
        fi
      fi
    done
  fi
}

main() {
  set_context
  check_jq
  get_team_repos
  change_permissions "$@"
}

main "$@"
