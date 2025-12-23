/// DAY 8: New Module & Simple Task Struct
/// 
/// Today you will:
/// 1. Start a new project: Task Bounty Board
/// 2. Create a Task struct
/// 3. Write a constructor function

module challenge::day_08 {
    use std::string::String;

    // TODO: Define a struct called 'Task' with:
    // - title: String
    // - reward: u64
    // - done: bool
    // Add 'copy' and 'drop' abilities
    // public struct Task has copy, drop {
    //     // Your fields here
    // }

    // TODO: Write a constructor function 'new_task'
    // that takes title and reward, returns a Task with done = false
    // public fun new_task(title: String, reward: u64): Task {
    //     // Your code here
    // }
}

module 0x0::day_08 {
    

    /// A simple task in the bounty board
    public struct Task has copy, drop {
        title: string::String,
        reward: u64,
        done: bool,
    }

    /// Create a new task
    public fun new_task(title: string::String, reward: u64): Task {
        Task {
            title,
            reward,
            done: false,
        }
    }

    #[test]
    fun test_new_task() {
        let task = new_task(string::utf8(b"Fix bug"), 100);

        assert!(task.done == false);
        assert!(task.reward == 100);
    }
}
