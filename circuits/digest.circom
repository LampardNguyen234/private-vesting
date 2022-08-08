pragma circom 2.0.0;

include "circomlib/circuits/mimcsponge.circom";
include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/bitify.circom";

template Pedersen1() {
    signal input in;
    signal output out;

    component tmpBits = Num2Bits(248);
    tmpBits.in <== in;

    component hasher = Pedersen(248);
    for (var i = 0; i < 248; i++) {
        hasher.in[i] <== tmpBits.out[i];
    }

    out <== hasher.out[0];
}

template Pedersen2() {
    signal input ins[2];
    signal output out;

    component tmpBits1 = Num2Bits(248);
    tmpBits1.in <== ins[0];
    component tmpBits2 = Num2Bits(248);
    tmpBits2.in <== ins[1];

    component hasher = Pedersen(496);
    for (var i = 0; i < 248; i++) {
        hasher.in[i] <== tmpBits1.out[i];
        hasher.in[i+248] <== tmpBits2.out[i];
    }

    out <== hasher.out[0];
}

template Pedersen3() {
    signal input ins[3];
    signal output out;

    component tmpBits1 = Num2Bits(248);
    tmpBits1.in <== ins[0];
    component tmpBits2 = Num2Bits(248);
    tmpBits2.in <== ins[1];
    component tmpBits3 = Num2Bits(248);
    tmpBits3.in <== ins[2];

    component hasher = Pedersen(744);
    for (var i = 0; i < 248; i++) {
        hasher.in[i] <== tmpBits1.out[i];
        hasher.in[i+248] <== tmpBits2.out[i];
        hasher.in[i+496] <== tmpBits3.out[i];
    }

    out <== hasher.out[0];
}

template Pedersen4() {
    signal input ins[4];
    signal output out;

    component tmpBits1 = Num2Bits(248);
    tmpBits1.in <== ins[0];
    component tmpBits2 = Num2Bits(248);
    tmpBits2.in <== ins[1];
    component tmpBits3 = Num2Bits(248);
    tmpBits3.in <== ins[2];
    component tmpBits4 = Num2Bits(248);
    tmpBits4.in <== ins[3];

    component hasher = Pedersen(992);
    for (var i = 0; i < 248; i++) {
        hasher.in[i] <== tmpBits1.out[i];
        hasher.in[i+248] <== tmpBits2.out[i];
        hasher.in[i+496] <== tmpBits3.out[i];
        hasher.in[i+744] <== tmpBits4.out[i];
    }

    out <== hasher.out[0];
}