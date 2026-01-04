/// DAY 20: Events (Optional but Small)
/// 
/// Today you will:
/// 1. Learn about events
/// 2. Define an event struct
/// 3. Emit events when actions happen
///
/// Note: You can copy code from day_19/sources/solution.move if needed
module challenge::farm_simulator {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;
    
    // Constants for plotId validation
    const MIN_PLOT_ID: u8 = 1;
    const MAX_PLOT_ID: u8 = 20;
    const MAX_PLOTS: u64 = 20;
    
    // Error codes
    const EInvalidPlotId: u64 = 0;
    const EPlotAlreadyPlanted: u64 = 1;
    const EMaxPlotsReached: u64 = 2;
    const EPlotNotPlanted: u64 = 3;
    
    // Event struct
    public struct PlantEvent has copy, drop {
        planted_after: u64,
    }
    
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
    
    // Entry function to plant on farm - now emits event
    entry fun plant_on_farm_entry(farm: &mut Farm, plotId: u8) {
        plant_on_farm(farm, plotId);
        let planted_count = total_planted(farm);
        event::emit(PlantEvent { planted_after: planted_count });
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
    fun test_plant_event_emitted() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        // Create farm
        {
            let ctx = test_scenario::ctx(scenario);
            create_farm(ctx);
        };
        
        // Plant and verify event is emitted
        test_scenario::next_tx(scenario, owner);
        {
            let mut farm = test_scenario::take_shared<Farm>(scenario);
            
            plant_on_farm_entry(&mut farm, 1);
            assert!(total_planted(&farm) == 1, 0);
            
            plant_on_farm_entry(&mut farm, 2);
            assert!(total_planted(&farm) == 2, 1);
            
            plant_on_farm_entry(&mut farm, 3);
            assert!(total_planted(&farm) == 3, 2);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_multiple_plants_emit_events() {
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
            
            // Each plant should emit an event with updated count
            plant_on_farm_entry(&mut farm, 1);  // planted_after: 1
            plant_on_farm_entry(&mut farm, 5);  // planted_after: 2
            plant_on_farm_entry(&mut farm, 10); // planted_after: 3
            plant_on_farm_entry(&mut farm, 15); // planted_after: 4
            
            assert!(total_planted(&farm) == 4, 0);
            
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_query_functions() {
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
            plant_on_farm_entry(&mut farm, 0);
            test_scenario::return_shared(farm);
        };
        
        test_scenario::end(scenario_val);
    }
}


    // TODO: Define an event struct called 'PlantEvent' that:
    // - Has a field 'planted_after' of type u64
    // - Has 'copy' and 'drop' abilities (required for events)
    // - Is marked as 'public struct'

    // TODO: Create/update the entry function 'plant_on_farm_entry' that:
    // - Takes farm: &mut Farm and plotId: u8 as parameters
    // - Calls plant_on_farm(farm, plotId) to plant
    // - Gets the total planted count using total_planted(farm)
    // - Emits a PlantEvent using event::emit() with the planted_after value

    // TODO: Create the entry function 'harvest_from_farm_entry' that:
    // - Takes farm: &mut Farm and plotId: u8 as parameters
    // - Calls harvest_from_farm(farm, plotId) to harvest


