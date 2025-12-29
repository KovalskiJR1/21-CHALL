module challenge::bounty_board {
    use sui::object;
    use sui::transfer;
    use sui::tx_context::TxContext;
    use std::string::{Self, String};

    // Structs
    public struct BountyBoard has key {
        id: object::UID,
        tasks: vector<Task>,
    }

    public struct Task has store, drop, copy {
        description: String,
        reward: u64,
        completed: bool,
    }

    // Functions
    public fun create_board(ctx: &mut TxContext) {
        let board = BountyBoard {
            id: object::new(ctx),
            tasks: vector::empty(),
        };
        transfer::share_object(board);
    }

    public fun add_task(
        board: &mut BountyBoard,
        description: vector<u8>,
        reward: u64,
    ) {
        let task = Task {
            description: string::utf8(description),
            reward,
            completed: false,
        };
        vector::push_back(&mut board.tasks, task);
    }

    public fun complete_task(board: &mut BountyBoard, task_index: u64) {
        let task = vector::borrow_mut(&mut board.tasks, task_index);
        task.completed = true;
    }

    public fun get_completed_count(board: &BountyBoard): u64 {
        let mut count = 0;
        let mut i = 0;
        let len = vector::length(&board.tasks);
        
        while (i < len) {
            let task = vector::borrow(&board.tasks, i);
            if (task.completed) {
                count = count + 1;
            };
            i = i + 1;
        };
        
        count
    }

    public fun calculate_total_reward(board: &BountyBoard): u64 {
        let mut total = 0;
        let mut i = 0;
        let len = vector::length(&board.tasks);
        
        while (i < len) {
            let task = vector::borrow(&board.tasks, i);
            if (task.completed) {
                total = total + task.reward;
            };
            i = i + 1;
        };
        
        total
    }

    // Test-only functions
    #[test_only]
    public fun get_task_count(board: &BountyBoard): u64 {
        vector::length(&board.tasks)
    }

    #[test_only]
    public fun is_task_completed(board: &BountyBoard, task_index: u64): bool {
        let task = vector::borrow(&board.tasks, task_index);
        task.completed
    }

    // Tests
    #[test_only]
    use sui::test_scenario;

    #[test]
    fun test_create_board_and_add_task() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        // Create board
        {
            let ctx = test_scenario::ctx(scenario);
            create_board(ctx);
        };

        // Add task
        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            add_task(&mut board, b"Complete documentation", 100);
            add_task(&mut board, b"Fix bug in module", 200);
            
            assert!(get_task_count(&board) == 2, 0);
            assert!(!is_task_completed(&board, 0), 1);
            assert!(!is_task_completed(&board, 1), 2);
            
            test_scenario::return_shared(board);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_complete_task_and_verify_count() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        // Create board and add tasks
        {
            let ctx = test_scenario::ctx(scenario);
            create_board(ctx);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            add_task(&mut board, b"Task 1", 100);
            add_task(&mut board, b"Task 2", 200);
            add_task(&mut board, b"Task 3", 300);
            
            test_scenario::return_shared(board);
        };

        // Complete some tasks
        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            complete_task(&mut board, 0);
            complete_task(&mut board, 2);
            
            assert!(is_task_completed(&board, 0), 0);
            assert!(!is_task_completed(&board, 1), 1);
            assert!(is_task_completed(&board, 2), 2);
            assert!(get_completed_count(&board) == 2, 3);
            
            test_scenario::return_shared(board);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_calculate_total_reward() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        // Create board
        {
            let ctx = test_scenario::ctx(scenario);
            create_board(ctx);
        };

        // Add tasks with different rewards
        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            add_task(&mut board, b"Easy task", 50);
            add_task(&mut board, b"Medium task", 150);
            add_task(&mut board, b"Hard task", 300);
            add_task(&mut board, b"Expert task", 500);
            
            test_scenario::return_shared(board);
        };

        // Complete some tasks and verify total reward
        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            // Complete first, second, and fourth tasks
            complete_task(&mut board, 0); // 50
            complete_task(&mut board, 1); // 150
            complete_task(&mut board, 3); // 500
            
            let total = calculate_total_reward(&board);
            assert!(total == 700, 0); // 50 + 150 + 500
            
            test_scenario::return_shared(board);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_empty_board() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        {
            let ctx = test_scenario::ctx(scenario);
            create_board(ctx);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let board = test_scenario::take_shared<BountyBoard>(scenario);
            
            assert!(get_task_count(&board) == 0, 0);
            assert!(get_completed_count(&board) == 0, 1);
            assert!(calculate_total_reward(&board) == 0, 2);
            
            test_scenario::return_shared(board);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_all_tasks_completed() {
        let owner = @0xA;
        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        {
            let ctx = test_scenario::ctx(scenario);
            create_board(ctx);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let mut board = test_scenario::take_shared<BountyBoard>(scenario);
            
            add_task(&mut board, b"Task A", 100);
            add_task(&mut board, b"Task B", 200);
            
            complete_task(&mut board, 0);
            complete_task(&mut board, 1);
            
            assert!(get_completed_count(&board) == 2, 0);
            assert!(calculate_total_reward(&board) == 300, 1);
            
            test_scenario::return_shared(board);
        };

        test_scenario::end(scenario_val);
    }
}