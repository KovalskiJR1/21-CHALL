module challenge::day_10 {
    use std::string::String;

    /// Task durumları
    public enum TaskStatus has copy, drop , store {
        Open,
        Completed,
    }
    /// Task yapısı
    public struct Task has copy, drop , store {
        id: u64,
        description: String,
        status: TaskStatus,
    }
     /// Yeni task oluşturur
    public fun new_task(id: u64, description: String): Task {
        Task {
            id,
            description,
            status: TaskStatus::Open,
        }
    }
    /// PUBLIC API
    /// Dışarıdan çağrılabilen fonksiyon
    public fun complete_task(task: &mut Task){
        set_completed(task);
    }
     /// PRIVATE helper
    /// Sadece bu modül içinde kullanılır
    fun set_completed(task: &mut Task) {
        task.status = TaskStatus::Completed;
    }

    /// Task açık mı?
    public fun is_open(task: &Task): bool {
        match (task.status) {
            TaskStatus::Open => true,
            TaskStatus::Completed => false,
        }
    }

    // ----------------
    // Unit Test
    // ----------------
    #[test]
    fun test_visibility_and_api() {
        let description = std::string::utf8(b"Visibility ogren");
        let mut task = new_task(1, description);

        // Başlangıçta açık olmalı
        assert!(is_open(&task), 0);

        // Public API ile tamamla
        complete_task(&mut task);

        // Artık açık olmamalı
        assert!(!is_open(&task), 1);
    }
}


