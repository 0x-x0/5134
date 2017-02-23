#!/bin/bash -e
export TEAMID=$(echo $TEAMPARAMS_PARAMS_TMID | awk '{print toupper($0)}')
export OWNERTOKEN=$(eval echo "$TEAMPARAMS_PARAMS_TOKEN")

check_jq() {
  {
    type jq &> /dev/null && echo "jq is already installed"
  } || {
    echo "Installing 'jq'"
    apt-get install -y jq
  }
}

# getTeamId() {
#   local teams=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $TOKEN" https://api.github.com/orgs/"$ORG"/teams)
#   TEAMID=$(echo $teams |  jq ".[] | select(.name==\"$TEAMNAME\") | .id")
# }

getTeamRepos() {
  local res=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNERTOKEN" https://api.github.com/teams/$TEAMID/repos)
  TEAMREPOS=$(echo $res |  jq ".[] | .name")
}

changePermissions() {
  local permission="$1"
  local data="{\"permission\": \"$permission\"}"
  for repo in $TEAMREPOS; do
    repoName=$(echo "$repo" | sed -e 's/^"//' -e 's/"$//')
    url="https://api.github.com/teams/$TEAMID/repos/$ORG/$repoName"
    local responseCode=$(curl --write-out %{http_code} --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNERTOKEN" $url)
    if [ $responseCode -eq 204 ]; then
      local res=$(curl --write-out %{http_code} --silent -X PUT -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.repository+json" -H "Authorization: token $OWNERTOKEN" $url -d "$data")
      if [ $res -eq 204 ]; then
        echo "Permission updated for $repoName"
      fi
    fi
  done
}

main() {
  check_jq
  #getTeamId
  getTeamRepos
  changePermissions "$@"
}

main "$@"
