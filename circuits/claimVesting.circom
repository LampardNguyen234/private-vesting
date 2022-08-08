pragma circom 2.0.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/comparators.circom";
include "merkleTree.circom";
include "digest.circom";

// CommitmentHasher returns:
//  - cm = Pedersen(pk || p || t || r1)
//  - sn_hat = Digest(sk || p)
template CommitmentHasher() {
    signal input pk;
    signal input sk;
    signal input p;
    signal input r1;
    signal input t;
    signal output cm;
    signal output sn_hat;
    signal output h_revoke_hat;

    // double check (sk,pk) correspondence.
    component keyHasher = Pedersen1();
    keyHasher.in <== sk;
    keyHasher.out === pk;

    component revokeHasher = Pedersen2();
    revokeHasher.ins[0] <== p;
    revokeHasher.ins[1] <== t;

    component cmHasher = Pedersen4();
    cmHasher.ins[0] <== pk;
    cmHasher.ins[1] <== p;
    cmHasher.ins[2] <== t;
    cmHasher.ins[3] <== r1;

    component snHasher = Pedersen2();
    snHasher.ins[0] <== sk;
    snHasher.ins[1] <== p;

    cm <== cmHasher.out;
    sn_hat <== snHasher.out;
    h_revoke_hat <== keyHasher.out;
}

// Verifies that commitment that corresponds to given secret and sn is included in the merkle tree of deposits
template ClaimVesting(levels) {
    // public signal inputs
    signal input root;
    signal input snHash;
    signal input snRevokeHash;
    signal input currentTime;
    signal input recipient; // not taking part in any computations
    signal input relayer;  // not taking part in any computations
    signal input fee;      // not taking part in any computations
    
    // private signal inputs
    signal input p;
    signal input r1;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input pk;
    signal input sk;
    signal input t;

    component comHasher = CommitmentHasher();
    comHasher.pk <== pk;
    comHasher.sk <== sk;
    comHasher.p <== p;
    comHasher.r1 <== r1;
    comHasher.t <== t;
    
    // Ensure that the snHash is correctedly evaluated.
    comHasher.sn_hat === snHash;

    // Ensure that the snRevokeHash is correctedly evaluated.
    comHasher.h_revoke_hat === snRevokeHash;

    // Ensure that the t has passed.
    assert(currentTime >= t);

    component tree = MerkleTreeChecker(levels);
    tree.leaf <== comHasher.cm;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }

    // Add hidden signals to make sure that tampering with recipient or fee will invalidate the snark proof
    // Most likely it is not required, but it's better to stay on the safe side and it only takes 2 constraints
    // Squares are used to prevent optimizer from removing those constraints
    signal recipientSquare;
    signal feeSquare;
    signal relayerSquare;
    recipientSquare <== recipient * recipient;
    feeSquare <== fee * fee;
    relayerSquare <== relayer * relayer;
}

// We make public the following inputs:
//  - root: the current commitment tree root.
//  - snHash: the hash of the sn, for checking double-spending.
//  - snRevokeHash: the hash for checking if the vesting note has been revoked.
//  - currentTime: the time at which the proof is generated.
//  - recipient: the address of the recipient.
//  - relayer: the address of the relayer.
//  - fee: a portion of fees paying the relayer.
component main {public [root, snHash, snRevokeHash, currentTime, recipient, relayer, fee]} = ClaimVesting(18);
