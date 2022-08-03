pragma circom 2.0.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/comparators.circom";
include "merkleTree.circom";
include "circomlib/circuits/mimcsponge.circom";

// Hash computes hash = MiMCSponge(msg).
template Hash() {
    signal input msg;
    signal output hash;

    component hasher = MiMCSponge(1, 220, 1);
    hasher.ins[0] <== msg;
    hasher.k <== 0;
    hash <== hasher.outs[0];
}

// CommitmentHasher returns:
//  - cm = MiMCSponge(pk || p || t || r1)
//  - sn_hat = MiMCSponge(sk || p)
template CommitmentHasher() {
    signal input pk;
    signal input sk;
    signal input sn;
    signal input r;
    signal input t;
    signal output cm;
    signal output sn_hat;

    // double check (sk,pk) correspondence.
    component keyHasher = Hash();
    keyHasher.msg <== sk;
    keyHasher.hash === pk;

    component cmHasher = MiMCSponge(4, 220, 1);
    cmHasher.ins[0] <== pk;
    cmHasher.ins[1] <== sn;
    cmHasher.ins[2] <== t;
    cmHasher.ins[3] <== r;
    cmHasher.k <== 0;

    component snHasher = MiMCSponge(2, 220, 1);
    snHasher.ins[0] <== sk;
    snHasher.ins[1] <== sn;
    snHasher.k <== 0;
    // component snBits = Num2Bits(248);
    // component rBits = Num2Bits(248);
    // component pkBits = Num2Bits(248);
    // component skBits = Num2Bits(248);
    // component tBits = Num2Bits(248);
    // snBits.in <== sn;
    // rBits.in <== r;
    // pkBits.in <== pk;
    // skBits.in <== sk;
    // tBits.in <== t;
    // for (var i = 0; i < 248; i++) {
    //     snHasher.in[i] <== skBits.out[i];
    //     snHasher.in[i+248] <== snBits.out[i];
    //     cmHasher.in[i] <== pkBits.out[i];
    //     cmHasher.in[i+248] <== snBits.out[i];
    //     cmHasher.in[i + 496] <== tBits.out[i];
    //     cmHasher.in[i + 744] <== rBits.out[i];
    // }

    cm <== cmHasher.outs[0];
    sn_hat <== snHasher.outs[0];
}

// Verifies that commitment that corresponds to given secret and sn is included in the merkle tree of deposits
template ClaimVesting(levels) {
    // public signal inputs
    signal input root;
    signal input snHash;
    signal input currentTime;
    signal input recipient; // not taking part in any computations
    signal input relayer;  // not taking part in any computations
    signal input fee;      // not taking part in any computations
    
    // private signal inputs
    signal input sn;
    signal input r;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input pk;
    signal input sk;
    signal input t;

    component comHasher = CommitmentHasher();
    comHasher.pk <== pk;
    comHasher.sk <== sk;
    comHasher.sn <== sn;
    comHasher.r <== r;
    comHasher.t <== t;
    
    // Ensure that the snHash is correctedly evaluated.
    comHasher.sn_hat === snHash;

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
//  - currentTime: the time at which the proof is generated.
//  - recipient: the address of the recipient.
//  - relayer: the address of the relayer.
//  - fee: a portion of fees paying the relayer.
component main {public [root, snHash, currentTime, recipient, relayer, fee]} = ClaimVesting(18);
