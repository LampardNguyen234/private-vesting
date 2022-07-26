pragma circom 2.0.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/comparators.circom";
include "merkleTree.circom";
include "digest.circom";

// computes h_revoke_hat = Digest(p || t), commitment = Pedersen(p || t || r2)
template CommitmentHasher() {
    signal input p;
    signal input r2;
    signal input t;
    signal output commitment;
    signal output h_revoke_hat;

    component nullifierHasher = Pedersen2();
    nullifierHasher.ins[0] <== p;
    nullifierHasher.ins[1] <== t;

    component commitmentHasher = Pedersen3();
    commitmentHasher.ins[0] <== p;
    commitmentHasher.ins[1] <== t;
    commitmentHasher.ins[2] <== r2;

    commitment <== commitmentHasher.out;
    h_revoke_hat <== nullifierHasher.out;
}

// Verifies that commitment that corresponds to given secret and nullifier is included in the merkle tree of deposits
template RevokeVesting(levels) {
    // public input signals
    signal input root;
    signal input h_revoke_hat;
    signal input currentTime;

    // private input signals
    signal input p;
    signal input r2;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input t;

    component hasher = CommitmentHasher();
    hasher.p <== p;
    hasher.r2 <== r2;
    hasher.t <== t;

    // Ensure that the nullifierHash is correctedly evaluated.
    hasher.h_revoke_hat === h_revoke_hat;

    // Ensure that the unlockedTime has not passed.
    assert(currentTime < t);

    component tree = MerkleTreeChecker(levels);
    tree.leaf <== hasher.commitment;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }
}

// We make public the following inputs:
//  - root: the current commitment tree root.
//  - h_revoke_hat: the hash of the nullifier, for checking double-revoking.
//  - currentTime: the time at which the proof is generated.
component main {public [root, h_revoke_hat, currentTime]} = RevokeVesting(18);
