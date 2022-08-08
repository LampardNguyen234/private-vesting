const RevokeVerifier = artifacts.require('RevokeVerifier')

module.exports = function (deployer) {
  deployer.deploy(RevokeVerifier)
}