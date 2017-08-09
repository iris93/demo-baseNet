#!/bin/bash
#
# Copyright Tongji Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi
starttime=$(date +%s)

# echo "POST request Enroll on Org1  ..."
# echo
# ORG1_TOKEN=$(curl -s -X POST \
#   http://localhost:4000/users \
#   -H "content-type: application/x-www-form-urlencoded" \
#   -d 'username=Jim&orgName=org1')
# echo $ORG1_TOKEN
# ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
# echo
# echo "ORG1 token is $ORG1_TOKEN"
# echo
echo "POST request register on Org1  ..."
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

echo "enroll an user on Org1"
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

echo "POST request register and Enroll on Org2 ..."
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

echo "POST request register and Enroll on Org3 ..."
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
		"functionName":"register",
		"adminName":"admin",
		"adminSecret":"adminpw",
		"orgName":"org3",
		"newUser":{
		"username":"xiaowang",
		"department":"department1"}
	}')
echo $response
org3_password=$(echo $response | jq ".secret" | sed "s/\"//g")
echo
echo "password is $org3_password"
# #
echo "enroll an user"
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
	-H "password:$org3_password" \
  -d '{
		"functionName":"enroll",
		"orgName":"org3",
		"username":"xiaowang"
	}')
echo $response
echo
ORG3_TOKEN=$(echo $response | jq ".token" | sed "s/\"//g")
echo $ORG3_TOKEN

echo "POST request register and Enroll on Org4 ..."
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -d '{
		"functionName":"register",
		"adminName":"admin",
		"adminSecret":"adminpw",
		"orgName":"org4",
		"newUser":{
		"username":"xiaoli",
		"department":"department1"}
	}')
echo $response
org4_password=$(echo $response | jq ".secret" | sed "s/\"//g")
echo
echo "password is $org4_password"
# #
echo "enroll an user"
response=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
	-H "password:$org4_password" \
  -d '{
		"functionName":"enroll",
		"orgName":"org4",
		"username":"xiaoli"
	}')
echo $response
echo
ORG4_TOKEN=$(echo $response | jq ".token" | sed "s/\"//g")
echo $ORG4_TOKEN

# echo
# ORG2_TOKEN=$(curl -s -X POST \
#   http://localhost:4000/users \
#   -H "content-type: application/x-www-form-urlencoded" \
#   -d 'username=Barry&orgName=org2')
# echo $ORG2_TOKEN
# ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
# echo
# echo "ORG2 token is $ORG2_TOKEN"
# echo

# ORG3_TOKEN=$(curl -s -X POST \
#   http://localhost:4000/users \
#   -H "content-type: application/x-www-form-urlencoded" \
#   -d 'username=Irisxu&orgName=org3')
# echo $ORG3_TOKEN
# ORG3_TOKEN=$(echo $ORG3_TOKEN | jq ".token" | sed "s/\"//g")
# echo
# echo "ORG3 token is $ORG3_TOKEN"
# echo
#
# ORG4_TOKEN=$(curl -s -X POST \
#   http://localhost:4000/users \
#   -H "content-type: application/x-www-form-urlencoded" \
#   -d 'username=xiaowang&orgName=org4')
# echo $ORG4_TOKEN
# ORG4_TOKEN=$(echo $ORG4_TOKEN | jq ".token" | sed "s/\"//g")
# echo
# echo "ORG4 token is $ORG4_TOKEN"
# echo

echo
echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo
sleep 5
echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
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
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"]
}'
echo
echo

echo "POST request Join channel on Org3"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG3_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:9051","localhost:9056"]
}'
echo
echo

echo "POST request Join channel on Org4"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG4_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:10051","localhost:10056"]
}'
echo
echo

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:7051","localhost:7056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo


echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo

echo "POST Install chaincode on Org3"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG3_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:9051","localhost:9056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo

echo "POST Install chaincode on Org4"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG4_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:10051","localhost:10056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo

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

echo "POST invoke chaincode on peers of Org1"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:7051"],
	"fcn":"move",
	"args":["a","b","10"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

echo "POST invoke chaincode on peers of Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["localhost:8051"],
	"fcn":"move",
	"args":["a","b","10"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/mycc?peer=peer1&fcn=query&args=%5B%22a%22%5D" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Block by blockNumber"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/blocks/1?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Transaction by TransactionID"
echo
curl -s -X GET http://localhost:4000/channels/mychannel/transactions/$TRX_ID?peer=peer1 \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

############################################################################
### TODO: What to pass to fetch the Block information
############################################################################
#echo "GET query Block by Hash"
#echo
#hash=????
#curl -s -X GET \
#  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
#  -H "authorization: Bearer $ORG1_TOKEN" \
#  -H "cache-control: no-cache" \
#  -H "content-type: application/json" \
#  -H "x-access-token: $ORG1_TOKEN"
#echo
#echo

echo "GET query ChainInfo"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Installed chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer1&type=installed" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Instantiated chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer1&type=instantiated" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Channels"
echo
curl -s -X GET \
  "http://localhost:4000/channels?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
