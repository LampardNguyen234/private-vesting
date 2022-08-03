pragma circom 2.0.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/comparators.circom";
include "merkleTree.circom";

// computes Pedersen(nullifier + secret)
template CommitmentHasher() {
    signal input nullifier;
    signal input secret;
    signal input unlockedTime;
    signal output commitment;
    signal output nullifierHash;

    component commitmentHasher = Pedersen(744);
    component nullifierHasher = Pedersen(496);
    component nullifierBits = Num2Bits(248);
    component secretBits = Num2Bits(248);
    component unlockedTimeBits = Num2Bits(248);
    nullifierBits.in <== nullifier;
    secretBits.in <== secret;
    unlockedTimeBits.in <== unlockedTime;
    for (var i = 0; i < 248; i++) {
        nullifierHasher.in[i] <== nullifierBits.out[i];
        nullifierHasher.in[i+248] <== unlockedTimeBits.out[i];
        commitmentHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i+248] <== unlockedTimeBits.out[i];
        commitmentHasher.in[i + 496] <== secretBits.out[i];
    }

    commitment <== commitmentHasher.out[0];
    nullifierHash <== nullifierHasher.out[0];
}

// Verifies that commitment that corresponds to given secret and nullifier is included in the merkle tree of deposits
template RevokeVesting(levels) {
    signal input root;
    signal input nullifierHash;
    signal input currentTime;
    signal input nullifier;
    signal input secret;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input publicKey;
    signal input unlockedTime;

    component hasher = CommitmentHasher();
    hasher.nullifier <== nullifier;
    hasher.secret <== secret;
    hasher.unlockedTime <== unlockedTime;

    // Ensure that the nullifierHash is correctedly evaluated.
    hasher.nullifierHash === nullifierHash;

    // Ensure that the unlockedTime has not passed.
    assert(currentTime < unlockedTime);

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
//  - nullifierHash: the hash of the nullifier, for checking double-spending.
//  - currentTime: the time at which the proof is generated.
component main {public [root, nullifierHash, currentTime]} = RevokeVesting(18);
