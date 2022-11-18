int aaabs(int a);

int main() {
    volatile int a = -7777;
    int b = aaabs(a);
    return b;
}

int aaabs(int x) {   
    if (x < 0) return -x;
    else return x;
}
