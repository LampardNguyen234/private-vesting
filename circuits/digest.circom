pragma circom 2.0.0;

include "circomlib/circuits/mimcsponge.circom";

// Digest computes hash = MiMCSponge(ins[0] || ins[1] || ...).
template Digest(numInputs) {
    signal input ins[numInputs];
    signal output hash;

    component hasher = MiMCSponge(numInputs, 220, 1);
    for (var i = 0; i < numInputs; i++) {
        hasher.ins[i] <== ins[i];
    }
    
    hasher.k <== 0;
    hash <== hasher.outs[0];
}