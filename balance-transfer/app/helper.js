/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an 'AS IS' BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('Helper');
logger.setLevel('DEBUG');

var path = require('path');
var util = require('util');
var fs = require('fs-extra');
var User = require('fabric-client/lib/User.js');
var crypto = require('crypto');
var copService = require('fabric-ca-client');
var config = require('../config.json');

var hfc = require('fabric-client');
hfc.addConfigFile(path.join(__dirname, 'network-config.json'));
hfc.setLogger(logger);
var ORGS = hfc.getConfigSetting('network-config');

var clients = {};
var channels = {};
var caClients = {};

// set up the client and channel objects for each org
for (let key in ORGS) {
	if (key.indexOf('org') === 0) {
		let client = new hfc();

		let cryptoSuite = hfc.newCryptoSuite();
		cryptoSuite.setCryptoKeyStore(hfc.newCryptoKeyStore({path: getKeyStoreForOrg(ORGS[key].name)}));
		client.setCryptoSuite(cryptoSuite);

		let channel = client.newChannel(config.channelName);
		channel.addOrderer(newOrderer(client));

		clients[key] = client;
		channels[key] = channel;

		setupPeers(channel, key, client);

		let caUrl = ORGS[key].ca;
		caClients[key] = new copService(caUrl, null /*defautl TLS opts*/, '' /* default CA */, cryptoSuite);
	}
}

function setupPeers(channel, org, client) {
	for (let key in ORGS[org]) {
		if (key.indexOf('peer') === 0) {
			let data = fs.readFileSync(path.join(__dirname, ORGS[org][key]['tls_cacerts']));
			let peer = client.newPeer(
				ORGS[org][key].requests,
				{
					pem: Buffer.from(data).toString(),
					'ssl-target-name-override': ORGS[org][key]['server-hostname']
				}
			);

			channel.addPeer(peer);
		}
	}
}

function newOrderer(client) {
	var caRootsPath = ORGS.orderer.tls_cacerts;
	let data = fs.readFileSync(path.join(__dirname, caRootsPath));
	let caroots = Buffer.from(data).toString();
	return client.newOrderer(config.orderer, {
		'pem': caroots,
		'ssl-target-name-override': ORGS.orderer['server-hostname']
	});
}

function readAllFiles(dir) {
	var files = fs.readdirSync(dir);
	var certs = [];
	files.forEach((file_name) => {
		let file_path = path.join(dir,file_name);
		let data = fs.readFileSync(file_path);
		certs.push(data);
	});
	return certs;
}

function getOrgName(org) {
	return ORGS[org].name;
}

function getKeyStoreForOrg(org) {
	return config.keyValueStore + '_' + org;
}

function newRemotes(urls, forPeers, userOrg) {
	var targets = [];
	// find the peer that match the urls
	outer:
	for (let index in urls) {
		let peerUrl = urls[index];

		let found = false;
		for (let key in ORGS) {
			if (key.indexOf('org') === 0) {
				// if looking for event hubs, an app can only connect to
				// event hubs in its own org
				if (!forPeers && key !== userOrg) {
					continue;
				}

				let org = ORGS[key];
				let client = getClientForOrg(key);

				for (let prop in org) {
					if (prop.indexOf('peer') === 0) {
						if (org[prop]['requests'].indexOf(peerUrl) >= 0) {
							// found a peer matching the subject url
							if (forPeers) {
								let data = fs.readFileSync(path.join(__dirname, org[prop]['tls_cacerts']));
								targets.push(client.newPeer('grpcs://' + peerUrl, {
									pem: Buffer.from(data).toString(),
									'ssl-target-name-override': org[prop]['server-hostname']
								}));

								continue outer;
							} else {
								let eh = client.newEventHub();
								let data = fs.readFileSync(path.join(__dirname, org[prop]['tls_cacerts']));
								eh.setPeerAddr(org[prop]['events'], {
									pem: Buffer.from(data).toString(),
									'ssl-target-name-override': org[prop]['server-hostname']
								});
								targets.push(eh);

								continue outer;
							}
						}
					}
				}
			}
		}

		if (!found) {
			logger.error(util.format('Failed to find a peer matching the url %s', peerUrl));
		}
	}

	return targets;
}

//-------------------------------------//
// APIs
//-------------------------------------//
var getChannelForOrg = function(org) {
	return channels[org];
};

var getClientForOrg = function(org) {
	return clients[org];
};

var newPeers = function(urls) {
	return newRemotes(urls, true);
};

var newEventHubs = function(urls, org) {
	return newRemotes(urls, false, org);
};

var getMspID = function(org) {
	logger.debug('Msp ID : ' + ORGS[org].mspid);
	return ORGS[org].mspid;
};

var enrollUser = function(userName,userSecret,userOrg,isJson){
	var username = userName;
  var password = userSecret;
	var member;
	var client = getClientForOrg(userOrg);

	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(userOrg))
	}).then((store) => {
		client.setStateStore(store);
		//NOTE: This workaround is required to be able to switch user context
		// in the client instance
		client._userContext = null;
		return client.getUserContext(userName, true).then((user) => {
			if (user && user.isEnrolled()) {
				if (user._enrollmentSecret===password) {
					logger.info('Successfully loaded member from persistence');
					return user;
				}else {
					logger.error('Failed to enroll and persist user. Error: The password is wrong!!!' );
					return "The password is wrong!!!"
				}
			} else {
				let caClient = caClients[userOrg];
				// need to enroll it with CA server
				return caClient.enroll({
					enrollmentID: username,
					enrollmentSecret: password
				}).then((enrollment) => {
					logger.info('Successfully enrolled user \'' + userName + '\'');
					member = new User(userName, client);
					return member.setEnrollment(enrollment.key, enrollment.certificate,
						getMspID(userOrg));
				}).then(() => {
					return client.setUserContext(member);
				}).then(() => {
					return member;
				}).catch((err) => {
					logger.error('Failed to enroll and persist user. Error: ' + err.stack ?
						err.stack : err);
					logger.error('Please check username and password!!!');
					return ''+"Please check username and password!!!";
				});
			}
		});
	}).then((user) => {
		if (user&&typeof user!== 'string') {
			if (isJson && isJson === true) {
				var response = {
					success: true,
					message: userName + ' enrolled Successfully',
				};
				return response;
			}
			return user;
		}else{
			logger.error(userName + ' enroll failed');
			return '' + user;
		}
	}, (err) => {
		logger.error(userName + ' enroll failed');
		return '' + err;
	});
};
var adminEnrollUser = function(userName,userSecret,userOrg,isJson){
	var username = userName;
  var password = userSecret;
	var member;
	var client = getClientForOrg(userOrg);
	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(userOrg))
	}).then((store) => {
		client.setStateStore(store);
		//NOTE: This workaround is required to be able to switch user context
		// in the client instance
		client._userContext = null;
		return client.getUserContext(userName, true).then((user) => {
				let caClient = caClients[userOrg];
				// need to enroll it with CA server
				return caClient.enroll({
					enrollmentID: username,
					enrollmentSecret: password
				}).then((enrollment) => {
					logger.info('Successfully enrolled user \'' + userName + '\'');
					member = new User(userName, client);
					return member.setEnrollment(enrollment.key, enrollment.certificate,
						getMspID(userOrg));
				}).then(() => {
					return client.setUserContext(member);
				}).then(() => {
					return member;
				}).catch((err) => {
					logger.error('Failed to enroll and persist user. Error: ' + err.stack ?
						err.stack : err);
					logger.error('Please check username and password!!!');
					return ''+"Please check username and password!!!";
				});
		});
	}).then((user) => {
		if (user&&typeof user!== 'string') {
			if (isJson && isJson === true) {
				var response = {
					success: true,
					secret: user._enrollmentSecret,
					message: userName + ' enrolled Successfully',
				};
				return response;
			}
			return user;
		}else{
			logger.error(userName + ' enroll failed');
			return '' + user;
		}
	}, (err) => {
		logger.error(userName + ' enroll failed');
		return '' + err;
	});
};
var registerUsers = function(adminName,adminSecret,userOrg,newUser,isJson) {
	var member;
	var username = newUser.username;
	var department = newUser.department;
	var client = getClientForOrg(userOrg);
	var enrollmentSecret = null;
	var errormessage = null;
	// var cop = new copService(ORGS[userOrg].ca, tlsOptions, {
	// 	keysize: 256,
	// 	hash: 'SHA2'
	// });
	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(userOrg))
	}).then((store) => {
		client.setStateStore(store);
		//NOTE: Temporary workaround, as of alpha this is not fixed in node
		client._userContext = null;
		return client.getUserContext(username,true).then((user) => {
			if (user && user.isEnrolled()) {
				logger.error('Successfully loaded member from persistence,username has been used!');
				logger.error('username has been used!');
				return "username has been used!";
			} else {
				let caClient = caClients[userOrg];
				return adminEnrollUser(adminName,adminSecret,userOrg,false).then(function(adminUserObj) {
					member = adminUserObj;
					return caClient.register({
						enrollmentID: username,
						affiliation: userOrg +'.'+department
					}, member);
				}).then((secret) => {
					enrollmentSecret = secret;
					logger.debug(username + ' registered successfully');
					return caClient.enroll({
						enrollmentID: username,
						enrollmentSecret: secret
					});
				}, (err) => {
					logger.debug(username + ' failed to register');
					return '' + err;
					//return 'Failed to register '+username+'. Error: ' + err.stack ? err.stack : err;
				}).then((message) => {
					if (message && typeof message === 'string' && message.includes(
							'Error:')) {
						logger.error(username + ' enrollment failed');
						errormessage = message
						return message;
					}
					else {
						logger.debug(username + ' enrolled successfully');
						client.setUserContext(member);
						member = new User(username, client);
						member._enrollmentSecret = enrollmentSecret;
						return member.setEnrollment(message.key, message.certificate, getMspID(userOrg));
					}
				}).then(() => {

					client.setUserContext(member);
					return member;
				}, (err) => {
					logger.error(username + ' enroll failed');
					return '' + err;
				}).then((user) => {
					if (isJson && isJson === true ) {
						var response = {
							success: true,
							secret: user._enrollmentSecret,
							message: username + ' enrolled Successfully',
						};
						if (!response.secret) {
							return errormessage
						}
						else{return response;}

					}
					return user;
				}, (err) => {
					logger.error(username + ' enroll failed');
					return '' + err;
				});
			}
		});
	});
};



var getOrgAdmin = function(userOrg) {
	var admin = ORGS[userOrg].admin;
	var keyPath = path.join(__dirname, admin.key);
	var keyPEM = Buffer.from(readAllFiles(keyPath)[0]).toString();
	var certPath = path.join(__dirname, admin.cert);
	var certPEM = readAllFiles(certPath)[0].toString();

	var client = getClientForOrg(userOrg);
	var cryptoSuite = hfc.newCryptoSuite();
	if (userOrg) {
		cryptoSuite.setCryptoKeyStore(hfc.newCryptoKeyStore({path: getKeyStoreForOrg(getOrgName(userOrg))}));
		client.setCryptoSuite(cryptoSuite);
	}

	return hfc.newDefaultKeyValueStore({
		path: getKeyStoreForOrg(getOrgName(userOrg))
	}).then((store) => {
		client.setStateStore(store);

		return client.createUser({
			username: 'peer'+userOrg+'Admin',
			mspid: getMspID(userOrg),
			cryptoContent: {
				privateKeyPEM: keyPEM,
				signedCertPEM: certPEM
			}
		});
	});
};

var setupChaincodeDeploy = function() {
	process.env.GOPATH = path.join(__dirname, config.GOPATH);
};

var getLogger = function(moduleName) {
	var logger = log4js.getLogger(moduleName);
	logger.setLevel('DEBUG');
	return logger;
};

var getPeerAddressByName = function(org, peer) {
	var address = ORGS[org][peer].requests;
	return address.split('grpcs://')[1];
};

exports.getChannelForOrg = getChannelForOrg;
exports.getClientForOrg = getClientForOrg;
exports.getLogger = getLogger;
exports.setupChaincodeDeploy = setupChaincodeDeploy;
exports.getMspID = getMspID;
exports.ORGS = ORGS;
exports.newPeers = newPeers;
exports.newEventHubs = newEventHubs;
exports.getPeerAddressByName = getPeerAddressByName;
exports.getOrgAdmin = getOrgAdmin;
exports.registerUsers = registerUsers;
exports.enrollUser = enrollUser;
