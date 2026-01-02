/// DAY 18: Receiving Objects & Updating State
/// 
/// Today you will:
/// 1. Write entry functions that receive objects
/// 2. Update object state on-chain
/// 3. Understand how objects are passed in transactions
///
/// Note: The code includes plotId support. You can copy code from 
/// day_17/sources/solution.move if needed (note: plotId functionality has been added)
module challenge::farm_simulator {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    
    // Constants for plotId validation
    const MIN_PLOT_ID: u8 = 1;
    const MAX_PLOT_ID: u8 = 20;
    const MAX_PLOTS: u64 = 20;
    
    // Error codes
    const EInvalidPlotId: u64 = 0;
    const EPlotAlreadyPlanted: u64 = 1;
    const EMaxPlotsReached: u64 = 2;
    const EPlotNotPlanted: u64 = 3;
    
    // FarmCounters struct with copy, drop, and store abilities
    public struct FarmCounters has copy, drop, store {
        planted: u64,
        harvested: u64,
        plots: vector<u8>,
    }
    
    // Farm object with UID and key ability
    public struct Farm has key {
        id: UID,
        counters: FarmCounters,
    }
    
    // Entry function to create and share a farm
    entry fun create_farm(ctx: &mut TxContext) {
        let farm = new_farm(ctx);
        transfer::share_object(farm);
    }
    
    // Entry function to plant on farm
    entry fun plant_on_farm_entry(farm: &mut Farm, plotId: u8) {
        plant_on_farm(farm, plotId);
    }
    
    // Entry function to harvest from farm
    entry fun harvest_from_farm_entry(farm: &mut Farm, plotId: u8) {
        harvest_from_farm(farm, plotId);
    }
    
    // Helper function to plant on farm
    public fun plant_on_farm(farm: &mut Farm, plotId: u8) {
        plant(&mut farm.counters, plotId);
    }
    
    // Helper function to harvest from farm
    public fun harvest_from_farm(farm: &mut Farm, plotId: u8) {
        harvest(&mut farm.counters, plotId);
    }
    
    // Create new farm counters
    public fun new_counters(): FarmCounters {
        FarmCounters {
            planted: 0,
            harvested: 0,
            plots: vector::empty(),
        }
    }
    
    // Create new farm object
    public fun new_farm(ctx: &mut TxContext): Farm {
        Farm {
            id: object::new(ctx),
            counters: new_counters(),
        }
    }
    
    // Plant a crop on a specific plot
    public fun plant(counters: &mut FarmCounters, plotId: u8) {
        // Validate plotId is in range [1, 20]
        assert!(plotId >= MIN_PLOT_ID && plotId <= MAX_PLOT_ID, EInvalidPlotId);
        
        // Check if max plots reached
        assert!(vector::length(&counters.plots) < MAX_PLOTS, EMaxPlotsReached);
        
        // Check if plot already planted
        assert!(!vector::contains(&counters.plots, &plotId), EPlotAlreadyPlanted);
        
        // Add plot to planted plots
        vector::push_back(&mut counters.plots, plotId);
        
        // Increment planted counter
        counters.planted = counters.planted + 1;
    }
    
    // Harvest a crop from a specific plot
    public fun harvest(counters: &mut FarmCounters, plotId: u8) {
        // Validate plotId is in range [1, 20]
        assert!(plotId >= MIN_PLOT_ID && plotId <= MAX_PLOT_ID, EInvalidPlotId);
        
        // Check if plot is planted
        let (exists, index) = vector::index_of(&counters.plots, &plotId);
        assert!(exists, EPlotNotPlanted);
        
        // Remove plot from planted plots
        vector::remove(&mut counters.plots, index);
        
        // Increment harvested counter
        counters.harvested = counters.harvested + 1;
    }
    
    // Getter functions for testing
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
    
    #[test]
    fun test_plant_on_farm_entry() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Create farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // Plant using entry function
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 5);
            plant_on_farm_entry(&mut farm, 10);
            
            let counters = get_farm_counters(&farm);
            assert!(get_planted(counters) == 3, 0);
            assert!(get_plot_count(counters) == 3, 1);
            assert!(is_plot_planted(counters, 1), 2);
            assert!(is_plot_planted(counters, 5), 3);
            assert!(is_plot_planted(counters, 10), 4);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_harvest_from_farm_entry() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Create farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // Plant and harvest using entry functions
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 5);
            plant_on_farm_entry(&mut farm, 10);
            
            harvest_from_farm_entry(&mut farm, 1);
            harvest_from_farm_entry(&mut farm, 10);
            
            let counters = get_farm_counters(&farm);
            assert!(get_planted(counters) == 3, 0);
            assert!(get_harvested(counters) == 2, 1);
            assert!(get_plot_count(counters) == 1, 2);
            assert!(!is_plot_planted(counters, 1), 3);
            assert!(is_plot_planted(counters, 5), 4);
            assert!(!is_plot_planted(counters, 10), 5);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_multiple_users_with_entry_functions() {
        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Owner creates farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // User1 plants using entry function
        test_scenario::next_tx(scenario, user1);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 2);
            plant_on_farm_entry(&mut farm, 3);
            test_scenario::return_shared(farm);
        };
        
        // User2 plants and harvests using entry functions
        test_scenario::next_tx(scenario, user2);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 4);
            harvest_from_farm_entry(&mut farm, 1);
            harvest_from_farm_entry(&mut farm, 3);
            
            let counters = get_farm_counters(&farm);
            assert!(get_planted(counters) == 4, 0);
            assert!(get_harvested(counters) == 2, 1);
            assert!(get_plot_count(counters) == 2, 2);
            assert!(is_plot_planted(counters, 2), 3);
            assert!(is_plot_planted(counters, 4), 4);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_state_persistence() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Create farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // Plant in first transaction
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 2);
            test_scenario::return_shared(farm);
        };
        
        // Verify state persisted in second transaction
        test_scenario::next_tx(scenario, owner);
        {
            let farm = test_scenario::take_shared<Farm>(scenario);
            let counters = get_farm_counters(&farm);
            
            assert!(get_planted(counters) == 2, 0);
            assert!(get_plot_count(counters) == 2, 1);
            assert!(is_plot_planted(counters, 1), 2);
            assert!(is_plot_planted(counters, 2), 3);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = EInvalidPlotId)]
    fun test_plant_entry_invalid_plotid() {
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
            plant_on_farm_entry(&mut farm, 0); // Invalid plotId
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = EPlotAlreadyPlanted)]
    fun test_plant_entry_duplicate() {
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
            plant_on_farm_entry(&mut farm, 1); // Duplicate
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = EPlotNotPlanted)]
    fun test_harvest_entry_unplanted() {
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
            harvest_from_farm_entry(&mut farm, 1); // Not planted
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_create_farm_entry() {
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
            let counters = get_farm_counters(&farm);
            
            assert!(get_planted(counters) == 0, 0);
            assert!(get_harvested(counters) == 0, 1);
            assert!(get_plot_count(counters) == 0, 2);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
}

    // TODO: Write an entry function 'plant_on_farm_entry' that:
    // - Takes farm: &mut Farm, plotId: u8
    // - Calls plant_on_farm(farm, plotId)
    // entry fun plant_on_farm_entry(farm: &mut Farm, plotId: u8) {
    //     // Your code here
    // }

    // TODO: Write an entry function 'harvest_from_farm_entry' that:
    // - Takes farm: &mut Farm, plotId: u8
    // - Calls harvest_from_farm(farm, plotId)
    // entry fun harvest_from_farm_entry(farm: &mut Farm, plotId: u8) {
    //     // Your code here
    // }


