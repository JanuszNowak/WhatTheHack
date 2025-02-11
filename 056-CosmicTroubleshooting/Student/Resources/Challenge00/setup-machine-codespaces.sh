#!/bin/bash

echoerr() { printf "\033[0;31m%s\n\033[0m" "$*" >&2; }
echosuccess() { printf "\033[0;32m%s\n\033[0m" "$*" >&2; }

# check installed tooling
echo "Testing tools:";
az version
if [ $? == 0 ]; then
  echosuccess "[.] az cli tool...OK";
else
  echoerr "Error with 'az cli' tool!";
  exit 1;
fi


az bicep version
if [ $? == 0 ]; then
  echosuccess "[.] bicep support...OK";
else
  echo "Installing bicep"
  az bicep install
  exit 1;
fi


dotnet --version
if [ $? == 0 ]; then
  echosuccess "[.] dotnet support...OK";
else
  echoerr "Error with dotnet!";
  exit 1;
fi

jq --version
if [ $? == 0 ]; then
  echosuccess "[.] jq tool...OK";
else
  echoerr "Error with 'jq' tool!";
  exit 1;
fi

echo "Asking user to log in...";
# ask user for login
az login
if [ $? == 0 ]; then
  echosuccess "
  Your machine should be ready! Now proceed with ./deploy.sh script

  ";
else
  echoerr "Login into Azure failed!";
  exit 1;
fi
# set executable bit on ./deploy.sh
chmod +x ./deploy.sh