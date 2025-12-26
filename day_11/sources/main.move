module challenge::day_11 {
    use std::vector;
    use std::string::String;

    /// Day 9'dan gelen Task
    public struct Task has copy, drop, store {
        id: u64,
        description: String,
        done: bool,
    }

    ///  TaskBoard ÖNCE tanımlanır
    public struct TaskBoard has drop, store {
        owner: address,
        tasks: vector<Task>,
    }

    /// Yeni board oluştur
    public fun new_board(owner: address): TaskBoard {
        TaskBoard {
            owner,
            tasks: vector::empty<Task>(),
        }
    }

    /// Board'a task ekle
    public fun add_task(board: &mut TaskBoard, task: Task) {
        vector::push_back(&mut board.tasks, task);
    }
}
