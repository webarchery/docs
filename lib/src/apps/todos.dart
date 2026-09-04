import 'package:archery/archery/archery.dart';

enum TodoStatus {
  created("created"),
  working("working"),
  complete("complete"),
  archived("archived");

  final String progress;

  const TodoStatus(this.progress);

  static TodoStatus fromString(String progress) {
    return TodoStatus.values.firstWhere((status) => status.progress == progress.toLowerCase(), orElse: () => TodoStatus.created);
  }
}

class Todo extends Model with InstanceDatabaseOps<Todo> {
  late String task;
  late final String userUuid;
  TodoStatus status = TodoStatus.created;

  Todo({required this.task}) : super.fromJson({});

  Todo.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json['user_uuid'] != null && json['user_uuid'] is int) {
      userUuid = json['user_uuid'];
    }
    if (json['task'] != null && json['task'] is String) {
      task = json['task'];
    }
    if (json['progress'] != null && json['progress'] is String) {
      status = TodoStatus.fromString(json['progress']);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "uuid": uuid,
      // "user_uuid": userUuid,
      'task': task,
      'progress': "${status.progress[0].toUpperCase()}${status.progress.substring(1)}",
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toMetaJson() {
    return {
      "id": id,
      "uuid": uuid,
      // "user_uuid": userUuid,
      'task': task,
      'progress': "${status.progress[0].toUpperCase()}${status.progress.substring(1)}",
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  static Map<String, String> columnDefinitions = {'task': 'TEXT NOT NULL', 'progress': 'TEXT NOT NULL', 'user_uuid': 'TEXT NOT NULL'};
}

void todoRoutes(Router router) {
  router.group(
    middleware: [Auth.middleware],
    prefix: "/todos",
    routes: () {
      router.get("/", (request) async {

        // final user = await Auth.user(request);
        // final todos = await user?.todos;

        final todos = await Model.all<Todo>();
        return request.view("todos.index", {
          'todos': [...todos].map((todo) => todo.toJson()).toList(),
        });
      });

      router.post("/", (request) async {
        final task = await request.form.input('task');

        final validated = await request.validate(
            field: "task",
            rules: [
              Rule.required,
              Rule.max(255)
            ]
        );

        if (!validated) {
          request.redirectBack();
        }

        else {
          final todo = Todo(task: task.toString().trim());


          await todo.save();

          request.redirectBack();

          // final user = await Auth.user(request);
          //
          // if(user != null) {
          //   todo.userUuid = user.uuid!;
          //
          //   await todo.save();
          //
          //   request.redirectBack();
          // } else {
          //
          //   request.redirectBack();
          // }


        }
      });

      router.get("/{uuid:string}", (request) async {
        try {
          final uuid = RouteParams.get<String>("uuid");


          if (uuid == null) {
            return request.notFound();
          }

          final todo = await Model.firstWhere<Todo>(field: "uuid", value: uuid);

          if (todo == null) {
            return request.notFound();
          }

          return request.json(todo.toJson());
        } catch (e) {
          return request.notFound();
        }
      });

      router.delete("/{uuid:string}", (request) async {
        try {
          final uuid = RouteParams.get<String>("uuid");

          if (uuid == null) {
            return request.notFound();
          }

          final todo = await Model.firstWhere<Todo>(field: "uuid", value: uuid);
          await todo?.delete();

          request.redirectBack();
        } catch (e) {
          return request.notFound();
        }
      });

      router.patch("/truncate", (request) async {
        try {
          await Model.truncate<Todo>();
          request.redirectBack();
        } catch (e) {
          return request.notFound();
        }
      });
    },
  );
}
