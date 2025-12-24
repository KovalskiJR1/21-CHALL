module challenge::day_09 {
    use std::string::String;

    /// Görev durumlarını temsil eden Enum yapısı
    public enum TaskStatus has copy, drop, store {
        Open,
        Completed
    }

    /// Görev yapısı
    public struct Task has copy, drop, store {
        id: u64,
        description: String,
        status: TaskStatus,
    }

    /// Yeni bir görev oluşturur (Başlangıçta 'Open' durumundadır)
    public fun new_task(id: u64, description: String): Task {
        Task {
            id,
            description,
            status: TaskStatus::Open,
        }
    }

    /// Görevin durumunun 'Open' olup olmadığını kontrol eder
    public fun is_open(task: &Task): bool {
        match (task.status) {
            TaskStatus::Open => true,
            _ => false,
        }
    }

    /// Görevi 'Completed' olarak işaretler
    public fun complete_task(task: &mut Task) {
        task.status = TaskStatus::Completed;
    }

    // --- Unit Testler ---

    #[test]
    fun test_task_status() {
        let description = std::string::utf8(b"Enum ogren");
        let mut task = new_task(1, description);
        
        // Başlangıçta Open olmalı
        assert!(is_open(&task), 0);
        
        // Tamamlandığında status güncellenmeli
        complete_task(&mut task);
        
        // Durum artık Open olmamalı
        assert!(!is_open(&task), 1);
        
        // Match ile doğrulama
        match (task.status) {
            TaskStatus::Completed => (), // Başarılı
            _ => abort 2, 
        };
    }
} 