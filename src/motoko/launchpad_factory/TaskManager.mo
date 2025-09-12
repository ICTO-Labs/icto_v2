import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
module {
    // Define task types
    public type TaskType = {
        #DeployToken;
        #Distribution;
        #CreateLockToken;
        #CreateLP;
        // Add other task types if needed
    };

    // Task status
    public type TaskStatus = {
        #NotStarted;
        #InProgress;
        #Completed;
        #Failed: Text;
    };

    // Task details
    public type Task = {
        id: Nat;
        taskType: TaskType;
        status: TaskStatus;
        createdAt: Int;
        updatedAt: Int;
        retryCount: Nat;
        params: ?Text; // Parameters in JSON or text format
    };

    // Define type for task execution function
    public type TaskExecutor = (params: ?Text) -> async Result.Result<Text, Text>;

    // Class to manage tasks
    public class TaskManager() {
        private var nextTaskId: Nat = 0;
        private var tasks = HashMap.HashMap<Nat, Task>(0, Nat.equal, Hash.hash);

        // Create a new task
        public func createTask(taskType: TaskType, params: ?Text): Nat {
            let taskId = nextTaskId;
            nextTaskId += 1;
            
            let task: Task = {
                id = taskId;
                taskType = taskType;
                status = #NotStarted;
                createdAt = Time.now();
                updatedAt = Time.now();
                retryCount = 0;
                params = params;
            };
            
            tasks.put(taskId, task);
            return taskId;
        };

        // Update task status
        public func updateTaskStatus(taskId: Nat, status: TaskStatus): ?Task {
            switch (tasks.get(taskId)) {
                case (null) { return null; };
                case (?task) {
                    let updatedTask: Task = {
                        id = task.id;
                        taskType = task.taskType;
                        status = status;
                        createdAt = task.createdAt;
                        updatedAt = Time.now();
                        retryCount = task.retryCount;
                        params = task.params;
                    };
                    tasks.put(taskId, updatedTask);
                    return ?updatedTask;
                };
            };
        };

        // Execute a task
        public func executeTask(taskId: Nat, executors: HashMap.HashMap<TaskType, TaskExecutor>): async () {
            switch (tasks.get(taskId)) {
                case (null) { return; };
                case (?task) {
                    // Update status to in progress
                    ignore updateTaskStatus(taskId, #InProgress);
                    
                    switch (executors.get(task.taskType)) {
                        case (null) {
                            ignore updateTaskStatus(taskId, #Failed("No executor found for task type"));
                        };
                        case (?executor) {
                            let result = await executor(task.params);
                            
                            // Update status based on result
                            switch (result) {
                                case (#ok(message)) {
                                    ignore updateTaskStatus(taskId, #Completed);
                                };
                                case (#err(error)) {
                                    ignore updateTaskStatus(taskId, #Failed(error));
                                };
                            };
                        };
                    };
                };
            };
        };

        // Get all tasks
        public func getAllTasks(): [Task] {
            return Iter.toArray(tasks.vals());
        };

        // Get a specific task
        public func getTask(taskId: Nat): ?Task {
            return tasks.get(taskId);
        };

        // Retry a task
        public func retryTask(taskId: Nat): ?Task {
            switch (tasks.get(taskId)) {
                case (null) { return null; };
                case (?task) {
                    // Update retry count
                    let updatedTask: Task = {
                        id = task.id;
                        taskType = task.taskType;
                        status = #NotStarted;
                        createdAt = task.createdAt;
                        updatedAt = Time.now();
                        retryCount = task.retryCount + 1;
                        params = task.params;
                    };
                    tasks.put(taskId, updatedTask);
                    return ?updatedTask;
                };
            };
        };

        // Get the next task ID
        public func getNextTaskId(): Nat {
            return nextTaskId;
        };

        // Convert to stable storage
        public func toStable(): [(Nat, Task)] {
            return Iter.toArray(tasks.entries());
        };

        // Restore from stable storage
        public func fromStable(entries: [(Nat, Task)], nextId: Nat) {
            tasks := HashMap.fromIter<Nat, Task>(entries.vals(), 0, Nat.equal, Hash.hash);
            nextTaskId := nextId;
        };
    };
};