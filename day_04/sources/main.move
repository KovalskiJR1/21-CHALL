module 0x0::day_04 {
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

    /// Add habit to list (ownership moves)
    public fun add_habit(list: &mut HabitList, habit: Habit) {
        vector::push_back(&mut list.habits, habit);
    }

    #[test]
    fun test_add_habit() {
        let mut list = empty_list();

        let habit1 = new_habit(string::utf8(b"Drink Water"));
        let habit2 = new_habit(string::utf8(b"Read Book"));

        add_habit(&mut list, habit1);
        add_habit(&mut list, habit2);

        let len = vector::length(&list.habits);
        assert!(len == 2, 0);
    }
}
