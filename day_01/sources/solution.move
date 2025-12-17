/// DAY 1: Modules + Primitive Types - SOLUTION
///
/// This is the solution file for day 1.
/// Students should complete main.move, not this file.
///
/// To test this solution, temporarily rename main.move and use this file.

module challenge::day_01_solution {
    // Day 1: Basic module structure + primitive types

    // Constants in Move are defined at module level
    // They must be immutable and named in UPPERCASE

    const NUMBER: u64 = 42;
    const FLAG: bool = true;
    const MY_ADDRESS: address = @0x1;

    // Public helper functions to expose the constants
    // In Move the last expression is returned (no `return` needed)
    public fun get_number(): u64 {
        NUMBER
    }

    public fun is_flag_set(): bool {
        FLAG
    }

    public fun get_address(): address {
        MY_ADDRESS
    }

    // Example logic: add an input to the constant NUMBER
    public fun add_to_number(x: u64): u64 {
        x + NUMBER
    }
}



