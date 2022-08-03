pragma circom 2.0.0;

template GreaterThan() {
    signal input x;
    signal input y;

    assert (x > y);
}

component main = GreaterThan();
