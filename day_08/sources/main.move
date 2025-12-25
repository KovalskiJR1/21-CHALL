module 0x0::day_08 {
    use std::string;

    public struct Task has copy, drop {
        title: string::String,
        reward: u64,
        done: bool,
    }

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
