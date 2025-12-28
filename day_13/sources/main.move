module challenge::task_manager {
    // Move 2024: UID ve vector otomatik yüklendi, import gerekmez.

    public struct Task has store, copy, drop {
        reward: u64,
        is_completed: bool,
    }

    public struct TaskBoard has key, store {
        id: UID,
        tasks: vector<Task>,
    }

    public fun total_reward(board: &TaskBoard): u64 {
        let mut total = 0;
        let mut i = 0;
        let len = vector::length(&board.tasks);

        while (i < len) {
            let task = vector::borrow(&board.tasks, i);
            total = total + task.reward;
            i = i + 1;
        };

        total
    }

    public fun completed_count(board: &TaskBoard): u64 {
        let mut count = 0;
        let mut i = 0;
        let len = vector::length(&board.tasks);

        while (i < len) {
            let task = vector::borrow(&board.tasks, i);
            if (task.is_completed) {
                count = count + 1;
            };
            i = i + 1;
        };

        count
    }
}