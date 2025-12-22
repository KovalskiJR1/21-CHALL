module 0x0::day_07 {
    use std::vector;
    use std::string;

    /// Single habit
    public struct Habit has copy, drop {
        name: string::String,
        completed: bool,
    }

    /// List of habits
    public struct HabitList has drop {
        habits: vector<Habit>,
    }

    /// Create empty habit list
    public fun empty_list(): HabitList {
        HabitList {
            habits: vector::empty<Habit>(),
        }
    }

    /// Create a new habit using String
    public fun new_habit(name: string::String): Habit {
        Habit {
            name,
            completed: false,
        }
    }

    /// Helper: create habit from bytes
    public fun make_habit(name_bytes: vector<u8>): Habit {
        let name = string::utf8(name_bytes);
        new_habit(name)
    }

    /// Add habit to list
    public fun add_habit(list: &mut HabitList, habit: Habit) {
        vector::push_back(&mut list.habits, habit);
    }

    /// Mark habit as completed
    public fun complete_habit(list: &mut HabitList, index: u64) {
        let habit_ref = vector::borrow_mut(&mut list.habits, index);
        habit_ref.completed = true;
    }

    /// ---------- TESTS ----------

    #[test]
    fun test_add_habits_to_list() {
        let mut list = empty_list();

        let habit1 = make_habit(b"Drink Water");
        let habit2 = make_habit(b"Read Book");

        add_habit(&mut list, habit1);
        add_habit(&mut list, habit2);

        let len = vector::length(&list.habits);
        assert!(len == 2);
    }

    #[test]
    fun test_complete_habit() {
        let mut list = empty_list();

        let habit = make_habit(b"Exercise");
        add_habit(&mut list, habit);

        complete_habit(&mut list, 0);

        let habit_ref = vector::borrow(&list.habits, 0);
        assert!(habit_ref.completed == true);
    }
}
