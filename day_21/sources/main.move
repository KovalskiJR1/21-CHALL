/// DAY 21: Final Tests & Cleanup
/// 
/// Today you will:
/// 1. Write comprehensive tests for the farm
/// 2. Clean up your code
/// 3. Review what you've learned
///
/// Note: You can copy code from day_20/sources/solution.move if needed

module challenge::farm_simulator {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;
    
    // Constants
    const MIN_PLOT_ID: u8 = 1;
    const MAX_PLOT_ID: u8 = 20;
    const MAX_PLOTS: u64 = 20;
    
    // Error codes
    const E_INVALID_PLOT_ID: u64 = 0;
    const E_PLOT_ALREADY_EXISTS: u64 = 1;
    const E_PLOT_LIMIT_EXCEEDED: u64 = 2;
    const E_PLOT_NOT_FOUND: u64 = 3;
    
    // Events
    public struct PlantEvent has copy, drop {
        planted_after: u64,
    }
    
    // Structs
    public struct FarmCounters has copy, drop, store {
        planted: u64,
        harvested: u64,
        plots: vector<u8>,
    }
    
    public struct Farm has key {
        id: UID,
        counters: FarmCounters,
    }
    
    // Entry functions
    entry fun create_farm(ctx: &mut TxContext) {
        let farm = new_farm(ctx);
        transfer::share_object(farm);
    }
    
    entry fun plant_on_farm_entry(farm: &mut Farm, plotId: u8) {
        plant_on_farm(farm, plotId);
        let planted_count = total_planted(farm);
        event::emit(PlantEvent { planted_after: planted_count });
    }
    
    entry fun harvest_from_farm_entry(farm: &mut Farm, plotId: u8) {
        harvest_from_farm(farm, plotId);
    }
    
    // Query functions
    public fun total_planted(farm: &Farm): u64 {
        farm.counters.planted
    }
    
    public fun total_harvested(farm: &Farm): u64 {
        farm.counters.harvested
    }
    
    // Helper functions
    public fun plant_on_farm(farm: &mut Farm, plotId: u8) {
        plant(&mut farm.counters, plotId);
    }
    
    public fun harvest_from_farm(farm: &mut Farm, plotId: u8) {
        harvest(&mut farm.counters, plotId);
    }
    
    public fun new_counters(): FarmCounters {
        FarmCounters {
            planted: 0,
            harvested: 0,
            plots: vector::empty(),
        }
    }
    
    public fun new_farm(ctx: &mut TxContext): Farm {
        Farm {
            id: object::new(ctx),
            counters: new_counters(),
        }
    }
    
    public fun plant(counters: &mut FarmCounters, plotId: u8) {
        assert!(plotId >= MIN_PLOT_ID && plotId <= MAX_PLOT_ID, E_INVALID_PLOT_ID);
        assert!(vector::length(&counters.plots) < MAX_PLOTS, E_PLOT_LIMIT_EXCEEDED);
        assert!(!vector::contains(&counters.plots, &plotId), E_PLOT_ALREADY_EXISTS);
        
        vector::push_back(&mut counters.plots, plotId);
        counters.planted = counters.planted + 1;
    }
    
    public fun harvest(counters: &mut FarmCounters, plotId: u8) {
        assert!(plotId >= MIN_PLOT_ID && plotId <= MAX_PLOT_ID, E_INVALID_PLOT_ID);
        
        let (exists, index) = vector::index_of(&counters.plots, &plotId);
        assert!(exists, E_PLOT_NOT_FOUND);
        
        vector::remove(&mut counters.plots, index);
        counters.harvested = counters.harvested + 1;
    }
    
    // Test helpers
    #[test_only]
    public fun get_planted(counters: &FarmCounters): u64 {
        counters.planted
    }
    
    #[test_only]
    public fun get_harvested(counters: &FarmCounters): u64 {
        counters.harvested
    }
    
    #[test_only]
    public fun get_plot_count(counters: &FarmCounters): u64 {
        vector::length(&counters.plots)
    }
    
    #[test_only]
    public fun is_plot_planted(counters: &FarmCounters, plotId: u8): bool {
        vector::contains(&counters.plots, &plotId)
    }
    
    #[test_only]
    public fun get_farm_counters(farm: &Farm): &FarmCounters {
        &farm.counters
    }
    
    #[test_only]
    public fun destroy_farm_for_testing(farm: Farm) {
        let Farm { id, counters: _ } = farm;
        object::delete(id);
    }
    
    // Tests
    #[test_only]
    use sui::test_scenario;
    
    // Test 1: Create farm
    #[test]
    fun test_create_farm() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let farm = test_scenario::take_shared<Farm>(scenario);
            
            assert!(total_planted(&farm) == 0, 0);
            assert!(total_harvested(&farm) == 0, 1);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 2: Planting increases counter
    #[test]
    fun test_planting_increases_counter() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            assert!(total_planted(&farm) == 1, 0);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 3: Harvesting increases counter
    #[test]
    fun test_harvesting_increases_counter() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            harvest_from_farm_entry(&mut farm, 1);
            
            assert!(total_planted(&farm) == 1, 0);
            assert!(total_harvested(&farm) == 1, 1);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 4: Multiple operations
    #[test]
    fun test_multiple_operations() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 3);
            plant_on_farm_entry(&mut farm, 5);
            plant_on_farm_entry(&mut farm, 18);
            harvest_from_farm_entry(&mut farm, 5);
            
            assert!(total_planted(&farm) == 3, 0);
            assert!(total_harvested(&farm) == 1, 1);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 5: Invalid plot ID (0)
    #[test]
    #[expected_failure(abort_code = E_INVALID_PLOT_ID)]
    fun test_invalid_plot_id_zero() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 0);
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 5b: Invalid plot ID (21)
    #[test]
    #[expected_failure(abort_code = E_INVALID_PLOT_ID)]
    fun test_invalid_plot_id_high() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 21);
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 6: Duplicate plot
    #[test]
    #[expected_failure(abort_code = E_PLOT_ALREADY_EXISTS)]
    fun test_duplicate_plot() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 1);
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 7: Plot limit
    #[test]
    #[expected_failure(abort_code = E_PLOT_LIMIT_EXCEEDED)]
    fun test_plot_limit() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            let mut i = 1;
            while (i <= 20) {
                plant_on_farm_entry(&mut farm, i);
                i = i + 1;
            };
            
            plant_on_farm_entry(&mut farm, 1);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    // Test 8: Harvest nonexistent plot
    #[test]
    #[expected_failure(abort_code = E_PLOT_NOT_FOUND)]
    fun test_harvest_nonexistent_plot() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            harvest_from_farm_entry(&mut farm, 1);
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
}


    // TODO: Write comprehensive tests:
    // 
    // Test 1: test_create_farm
    // - Create a farm (shared object)
    // - Check initial counters are zero
    // - Use test_scenario::take_shared to get the farm
    // 
    // Test 2: test_planting_increases_counter
    // - Create farm, plant plotId 1
    // - Verify planted counter is 1
    // - Use test_scenario::take_shared and test_scenario::return_shared
    // 
    // Test 3: test_harvesting_increases_counter
    // - Create farm, plant plotId 1, then harvest plotId 1
    // - Verify both counters are 1
    // 
    // Test 4: test_multiple_operations
    // - Plant plotIds 3, 5, 18 (in any order)
    // - Harvest plotId 5
    // - Verify planted counter is 3, harvested counter is 1
    // 
    // Test 5: test_invalid_plot_id
    // - Try to plant plotId 0 or 21 (should abort)
    // 
    // Test 6: test_duplicate_plot
    // - Plant plotId 1, then try to plant plotId 1 again (should abort)
    // 
    // Test 7: test_plot_limit
    // - Try to plant 21 plots (should abort on the 21st)
    // 
    // Test 8: test_harvest_nonexistent_plot
    // - Try to harvest a plot that doesn't exist (should abort)
    // 
    // Use test_scenario::begin, test_scenario::next_tx, test_scenario::take_shared, etc.
    // Note: Since farm is a shared object, use test_scenario::take_shared instead of take_from_sender

    // TODO: Review all three projects (habit_tracker, bounty_board, farm_simulator)
    // Make sure function names are consistent
    // Remove any unnecessary comments
    // Ensure all tests pass


