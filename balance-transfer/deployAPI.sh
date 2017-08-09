jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
		"functionName":"register",
		"adminName":"admin",
		"adminSecret":"adminpw",
		"orgName":"org1",
		"newUser":{
		"username":"iris",
		"department":"department2"}
	}')
echo $response
org1_password=$(echo $response | jq ".secret" | sed "s/\"//g")
echo "password is $org1_password"
echo
# # #
echo $response
echo "enroll an user"
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
	-H "password:$org1_password" \
  -d '{
		"functionName":"enroll",
		"orgName":"org1",
		"username":"iris"
	}')
# department只能是department1或department2.不知道是在哪里设置的。。回头再找。
echo $response
echo
ORG1_TOKEN=$(echo $response | jq ".token" | sed "s/\"//g")
echo $ORG1_TOKEN

# add by cq 保存到php文件，方便能够直接引入
# echo "<?php
# # orgName=org1
# # userName=iris
# \$CHANNEL_PWD='$org1_password';
# \$CHANNEL_TOKEN='$ORG1_TOKEN';
# ?>" &> /var/www/zuche/channelpwd.php

response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
		"functionName":"register",
		"adminName":"admin",
		"adminSecret":"adminpw",
		"orgName":"org2",
		"newUser":{
		"username":"peng",
		"department":"department1"}
	}')
echo $response
org2_password=$(echo $response | jq ".secret" | sed "s/\"//g")
echo
echo "password is $org2_password"
# #
echo "enroll an user"
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
	-H "password:$org2_password" \
  -d '{
		"functionName":"enroll",
		"orgName":"org2",
		"username":"peng"
	}')
echo $response
echo
ORG2_TOKEN=$(echo $response | jq ".token" | sed "s/\"//g")
echo $ORG2_TOKEN
#
# ################################################################################
# ##                              Create channel                                ##
# ################################################################################
echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo
sleep 5
#
# ################################################################################
# ##                              Join channel                                ##
# ################################################################################
echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:7051","localhost:7056"]
}'
echo
echo

echo "POST request Join channel on Org2"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"]
}'
echo
# echo
#
# ################################################################################
# ##                             Install chaincode                              ##
# ################################################################################
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:7051","localhost:7056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo
#
echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo
#
# ################################################################################
# ##                           instantiate chaincode                            ##
# ################################################################################
echo "POST instantiate chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"chaincodeName":"mycc",
	"chaincodeVersion":"v0",
	"functionName":"init",
	"args":["a","100","b","200"]
}'
echo
echo
