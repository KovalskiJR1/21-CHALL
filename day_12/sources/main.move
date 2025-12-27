module challenge::day_12 {
    use std::string::{Self, String};

    public struct Task has copy, drop {
        title: String,
        done: bool,
    }

    public struct TaskBoard has copy, drop {
        owner: address,
        tasks: vector<Task>,
    }

    public fun new_board(owner: address): TaskBoard {
        TaskBoard {
            owner,
            tasks: vector::empty<Task>(),
        }
    }

    public fun add_task(board: &mut TaskBoard, task: Task) {
        vector::push_back(&mut board.tasks, task);
    }

    public fun find_task_by_title(
        board: &TaskBoard,
        title: &String
    ): option::Option<u64> {
        let mut i = 0;
        let len = vector::length(&board.tasks);

        while (i < len) {
            let task = vector::borrow(&board.tasks, i);
            if (&task.title == title) {
                return option::some(i)
            };
            i = i + 1;
        };

        option::none()
    }

    #[test]
    fun test_find_task_by_title() {
        let owner = @0x1;
        let mut board = new_board(owner);

        let task = Task {
            title: string::utf8(b"Learn Move"),
            done: false,
        };

        add_task(&mut board, task);

        let search = string::utf8(b"Learn Move");
        let result = find_task_by_title(&board, &search);

        assert!(option::is_some(&result), 0);
    }
}
