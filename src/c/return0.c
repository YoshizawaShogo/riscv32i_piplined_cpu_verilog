int f();

int main() {
    int a = 10;
    int b = a;
    if (f()) {
        return 0;
    }
    return 1;
}

int f() {
    return 1;
}