/// DAY 19: Simple Query Functions (View-like)
/// 
/// Today you will:
/// 1. Write read-only functions
/// 2. Query object state
/// 3. Write tests for query functions (optional)
///
/// Note: The code includes plotId support with all farm functions. 
/// You can reference day_18/sources/solution.move for basic structure, 
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
    
    // Query function: Get total planted count
    public fun total_planted(farm: &Farm): u64 {
        farm.counters.planted
    }
    
    // Query function: Get total harvested count
    public fun total_harvested(farm: &Farm): u64 {
        farm.counters.harvested
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
    fun test_query_functions() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Create farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // Initially both should be 0
        test_scenario::next_tx(scenario, owner);
        {
            let farm = test_scenario::take_shared<Farm>(scenario);
            
            assert!(total_planted(&farm) == 0, 0);
            assert!(total_harvested(&farm) == 0, 1);
            
            test_scenario::return_shared(farm);
        };
        
        // Plant some crops
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 2);
            plant_on_farm_entry(&mut farm, 3);
            
            assert!(total_planted(&farm) == 3, 2);
            assert!(total_harvested(&farm) == 0, 3);
            
            test_scenario::return_shared(farm);
        };
        
        // Harvest some crops
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            harvest_from_farm_entry(&mut farm, 1);
            harvest_from_farm_entry(&mut farm, 2);
            
            assert!(total_planted(&farm) == 3, 4);
            assert!(total_harvested(&farm) == 2, 5);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_query_functions_readonly() {
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
            plant_on_farm_entry(&mut farm, 5);
            plant_on_farm_entry(&mut farm, 10);
            test_scenario::return_shared(farm);
        };
        
        // Query functions don't need mutable reference
        test_scenario::next_tx(scenario, owner);
        {
            let farm = test_scenario::take_shared<Farm>(scenario);
            
            let planted = total_planted(&farm);
            let harvested = total_harvested(&farm);
            
            assert!(planted == 2, 0);
            assert!(harvested == 0, 1);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_multiple_queries() {
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
            
            // Plant 5, harvest 3
            plant_on_farm_entry(&mut farm, 1);
            plant_on_farm_entry(&mut farm, 2);
            plant_on_farm_entry(&mut farm, 3);
            plant_on_farm_entry(&mut farm, 4);
            plant_on_farm_entry(&mut farm, 5);
            
            harvest_from_farm_entry(&mut farm, 1);
            harvest_from_farm_entry(&mut farm, 3);
            harvest_from_farm_entry(&mut farm, 5);
            
            // Multiple queries on same object
            let p1 = total_planted(&farm);
            let h1 = total_harvested(&farm);
            let p2 = total_planted(&farm);
            let h2 = total_harvested(&farm);
            
            assert!(p1 == 5, 0);
            assert!(h1 == 3, 1);
            assert!(p2 == 5, 2);
            assert!(h2 == 3, 3);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_plant_on_farm_entry() {
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
        
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
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
}



    // TODO: Write a function 'total_planted' that:
    // - Takes farm: &Farm (read-only reference)
    // - Returns u64 (the planted count)
    // public fun total_planted(farm: &Farm): u64 {
    //     // Your code here
    // }

    // TODO: Write a function 'total_harvested' that:
    // - Takes farm: &Farm
    // - Returns u64 (the harvested count)
    // public fun total_harvested(farm: &Farm): u64 {
    //     // Your code here
    // }

    // TODO: (Optional) Write a test that:
    // - Creates a farm
    // - Plants once
    // - Checks that total_planted returns 1


