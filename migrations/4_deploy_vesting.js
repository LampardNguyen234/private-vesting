/* global artifacts */
require('dotenv').config({ path: '../.env' })
const Vesting = artifacts.require('AstraVesting')
const ClaimVerifier = artifacts.require('ClaimVerifier')
const RevokeVerifier = artifacts.require('RevokeVerifier')
const Hasher = artifacts.require('Hasher')

module.exports = function (deployer) {
  return deployer.then(async () => {
    const { MERKLE_TREE_HEIGHT, NOTE_AMOUNT } = process.env
    const claimVerifier = await ClaimVerifier.deployed()
    const revokeVerifier = await RevokeVerifier.deployed()
    const hasher = await Hasher.deployed()
    const astraVesting = await deployer.deploy(
      Vesting,
      claimVerifier.address,
      revokeVerifier.address,
      hasher.address,
      NOTE_AMOUNT,
      MERKLE_TREE_HEIGHT,
    )
    console.log('AstraVesting address', astraVesting.address)
  })
}