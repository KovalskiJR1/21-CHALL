module 0x0::day_05 {
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

    /// Create a new habit
    public fun new_habit(name: string::String): Habit {
        Habit {
            name,
            completed: false,
        }
    }

    /// Add habit to list
    public fun add_habit(list: &mut HabitList, habit: Habit) {
        vector::push_back(&mut list.habits, habit);
    }

    /// Mark habit as completed by index
    public fun complete_habit(list: &mut HabitList, index: u64) {
        let habit_ref = vector::borrow_mut(&mut list.habits, index);
        habit_ref.completed = true;
    }

    /// Count completed habits
    public fun completed_count(list: &HabitList): u64 {
        let mut i = 0;
        let mut count = 0;
        let len = vector::length(&list.habits);

        while (i < len) {
            let habit = vector::borrow(&list.habits, i);
            if (habit.completed) {
                count = count + 1;
            };
            i = i + 1;
        };

        count
    }

    #[test]
    fun test_complete_and_count() {
        let mut list = empty_list();

        let habit1 = new_habit(string::utf8(b"Drink Water"));
        let habit2 = new_habit(string::utf8(b"Read Book"));
        let habit3 = new_habit(string::utf8(b"Exercise"));

        add_habit(&mut list, habit1);
        add_habit(&mut list, habit2);
        add_habit(&mut list, habit3);

        // Complete 2 habits
        complete_habit(&mut list, 0);
        complete_habit(&mut list, 2);

        let completed = completed_count(&list);
        assert!(completed == 2, 1);
    }
}
