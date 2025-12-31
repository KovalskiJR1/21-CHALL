module challenge::farm_simulator {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    
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
    fun test_new_farm() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            let farm = new_farm(ctx);
            let counters = get_farm_counters(&farm);
            
            assert!(get_planted(counters) == 0, 0);
            assert!(get_harvested(counters) == 0, 1);
            assert!(get_plot_count(counters) == 0, 2);
            
            destroy_farm_for_testing(farm);
        };
        
        test_scenario::end(scenario_val);
    }
    
    #[test]
    fun test_new_counters() {
        let counters = new_counters();
        assert!(get_planted(&counters) == 0, 0);
        assert!(get_harvested(&counters) == 0, 1);
        assert!(get_plot_count(&counters) == 0, 2);
    }
    
    #[test]
    fun test_plant_single_plot() {
        let mut counters = new_counters();
        plant(&mut counters, 1);
        
        assert!(get_planted(&counters) == 1, 0);
        assert!(get_plot_count(&counters) == 1, 1);
        assert!(is_plot_planted(&counters, 1), 2);
    }
    
    #[test]
    fun test_plant_multiple_plots() {
        let mut counters = new_counters();
        plant(&mut counters, 1);
        plant(&mut counters, 5);
        plant(&mut counters, 10);
        
        assert!(get_planted(&counters) == 3, 0);
        assert!(get_plot_count(&counters) == 3, 1);
        assert!(is_plot_planted(&counters, 1), 2);
        assert!(is_plot_planted(&counters, 5), 3);
        assert!(is_plot_planted(&counters, 10), 4);
    }
    
    #[test]
    fun test_harvest_plot() {
        let mut counters = new_counters();
        plant(&mut counters, 1);
        harvest(&mut counters, 1);
        
        assert!(get_planted(&counters) == 1, 0);
        assert!(get_harvested(&counters) == 1, 1);
        assert!(get_plot_count(&counters) == 0, 2);
        assert!(!is_plot_planted(&counters, 1), 3);
    }
    
    #[test]
    fun test_plant_and_harvest_multiple() {
        let mut counters = new_counters();
        
        // Plant 3 plots
        plant(&mut counters, 1);
        plant(&mut counters, 2);
        plant(&mut counters, 3);
        
        // Harvest 2 plots
        harvest(&mut counters, 1);
        harvest(&mut counters, 3);
        
        assert!(get_planted(&counters) == 3, 0);
        assert!(get_harvested(&counters) == 2, 1);
        assert!(get_plot_count(&counters) == 1, 2);
        assert!(is_plot_planted(&counters, 2), 3);
    }
    
    #[test]
    #[expected_failure(abort_code = EInvalidPlotId)]
    fun test_plant_invalid_plotid_zero() {
        let mut counters = new_counters();
        plant(&mut counters, 0);
    }
    
    #[test]
    #[expected_failure(abort_code = EInvalidPlotId)]
    fun test_plant_invalid_plotid_too_high() {
        let mut counters = new_counters();
        plant(&mut counters, 21);
    }
    
    #[test]
    #[expected_failure(abort_code = EPlotAlreadyPlanted)]
    fun test_plant_duplicate_plot() {
        let mut counters = new_counters();
        plant(&mut counters, 1);
        plant(&mut counters, 1);
    }
    
    #[test]
    #[expected_failure(abort_code = EPlotNotPlanted)]
    fun test_harvest_unplanted_plot() {
        let mut counters = new_counters();
        harvest(&mut counters, 1);
    }
    
    #[test]
    #[expected_failure(abort_code = EMaxPlotsReached)]
    fun test_max_plots_limit() {
        let mut counters = new_counters();
        
        // Plant 20 plots (maximum)
        let mut i = 1;
        while (i <= 20) {
            plant(&mut counters, i);
            i = i + 1;
        };
        
        // Try to plant 21st plot (should fail)
        plant(&mut counters, 1);
    }
    
    #[test]
    fun test_boundary_plotids() {
        let mut counters = new_counters();
        
        // Test minimum valid plotId
        plant(&mut counters, 1);
        assert!(is_plot_planted(&counters, 1), 0);
        
        // Test maximum valid plotId
        plant(&mut counters, 20);
        assert!(is_plot_planted(&counters, 20), 1);
        
        assert!(get_plot_count(&counters) == 2, 2);
    }
    
    #[test]
    fun test_farm_with_operations() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        
        {
            let ctx = test_scenario::ctx(scenario);
            let mut farm = new_farm(ctx);
            
            // Plant some crops
            plant(&mut farm.counters, 1);
            plant(&mut farm.counters, 5);
            plant(&mut farm.counters, 10);
            
            let counters = get_farm_counters(&farm);
            assert!(get_planted(counters) == 3, 0);
            assert!(get_plot_count(counters) == 3, 1);
            
            // Harvest one crop
            harvest(&mut farm.counters, 5);
            
            let counters = get_farm_counters(&farm);
            assert!(get_harvested(counters) == 1, 2);
            assert!(get_plot_count(counters) == 2, 3);
            
            destroy_farm_for_testing(farm);
        };
        
        test_scenario::end(scenario_val);
    }
}