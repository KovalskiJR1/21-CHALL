module challenge::day_01 {
    const NUMBER: u64 = 42;
    const FLAG: bool = true;
    const MY_ADDRESS: address = @0x1;

    public fun get_number(): u64 {
        NUMBER
    }

    public fun is_flag_set(): bool {
        FLAG
    }

    public fun get_address(): address {
        MY_ADDRESS
    }

    public fun add_to_number(x: u64): u64 {
        x + NUMBER
    }
}

