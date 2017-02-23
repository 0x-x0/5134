#!/bin/bash -e
export ORG='shippersOrg'
export TEAM_ID=''
export TEAM_NAME='ship'
export GITHUB_API_URL='https://api.github.com'

export RES_PARAMS="team_params"
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"
export OWNER_TOKEN=$(eval echo "$"$RES_PARAMS_STR"_TOKEN")

check_jq() {
  {
    type jq &> /dev/null && echo "jq is already installed"
  } || {
    echo "Installing 'jq'"
    echo "----------------------------------------------"
    apt-get install -y jq
  }
}

get_team_id() {
  echo "Getting team id for $TEAM_NAME"
  echo "----------------------------------------------"
  echo $OWNER_TOKEN
  local url="$GITHUB_API_URL/orgs/$ORG/teams"
  echo $url
  local teams=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
  TEAMID=$(echo $teams |  jq ".[] | select(.name==\"$TEAMNAME\") | .id")
  echo $TEAMID
}

get_team_repos() {
  echo "Getting team repositories for $TEAM_NAME"
  echo "----------------------------------------------"

  local url="$GITHUB_API_URL/teams/$TEAMID/repos"
  local res=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
  TEAM_REPOS=$(echo $res |  jq ".[] | .name")
}

change_permissions() {
  echo "Chnaging permissions for $TEAM_NAME"
  echo "----------------------------------------------"

  local permission="$1"
  local data="{\"permission\": \"$permission\"}"
  for repo in $TEAM_REPOS; do
    #jq returned array of name has "" around the names hence escaping them here
    repo_name=$(echo "$repo" | sed -e 's/^"//' -e 's/"$//')
    url="$GITHUB_API_URL/teams/$TEAMID/repos/$ORG/$repo_name"

    #check if this repo is managed by this team
    local responseCode=$(curl --write-out %{http_code} --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
    if [ $responseCode -eq 204 ]; then
      local res=$(curl --write-out %{http_code} --silent -X PUT -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.repository+json" -H "Authorization: token $OWNER_TOKEN" $url -d "$data")
      if [ $res -eq 204 ]; then
        echo "Permission updated for $repo_name"
      else
        echo "Update permissions failed for $repo_name"
      fi
    fi
  done
}

main() {
  check_jq
  get_team_id
  get_team_repos
  change_permissions "$@"
}

main "$@"
