int aaabs(int a);

int main() {
    volatile int a = -7777;
    int b = aaabs(a);

    int c = a + b;
    return c;
}

int aaabs(int x) {   
    if (x < 0) return -x;
    else return x;
}
