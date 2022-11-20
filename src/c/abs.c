int my_abs(int a);

int main() {
    return my_abs(-7777);
}

int my_abs(int x) {   
    if (x < 0) return -x;
    else return x;
}
