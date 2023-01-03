# prerequisite
    riscv32-unknown-elf-gccをインストール
    iverilogをインストール

# usage
    $ make
    その後、build/result.logを見る

# リグレッションテスト

    $ git submodule update --init --recursive
    $ cd riscv-tests
    $ autoconf
    $ ./configure --prefix=$RISCV/target --with-xlen=32
    $ cd -
    $ make test

# 未対応
    CSR命令
    ECALL命令
    分岐予測　など