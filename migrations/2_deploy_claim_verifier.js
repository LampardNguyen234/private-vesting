const ClaimVerifier = artifacts.require('ClaimVerifier')

module.exports = function (deployer) {
  deployer.deploy(ClaimVerifier)
}