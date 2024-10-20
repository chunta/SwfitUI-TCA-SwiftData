import JsonServer from "json-server";
import type { JsonServerRouter } from "json-server";
import { Request, Response } from "express";
import { LowdbSync } from "lowdb";
import {
  object,
  parse,
  string,
  array,
  picklist,
  ValiError,
  regex,
  nonOptional,
  nullable,
} from "valibot";

type Status = "todo" | "inProgress" | "done";

type ToDo = {
  id: number;
  title: string;
  tags: string[];
  deadline: string;
  status: Status;
  createdAt: string;
  updatedAt: string;
};

type DB = {
  todos: ToDo[];
};

type ValidationError = {
  message: string;
  key: string;
  value?: string;
};

const isoDateStringRegex =
  /^\d{4}-(?:0[1-9]|1[0-2])-(?:[0-2][1-9]|[1-3]0|3[01])T(?:[0-1][0-9]|2[0-3])(?::[0-6]\d)(?::[0-6]\d)?(?:\.\d{3})?(?:[+-][0-2]\d:[0-5]\d|Z)?$/;

// POST時のvalibotのschema
const TodoSchema = object({
  title: nonOptional(string("Field is not a string"), "Field is required"),
  tags: array(string("Field is not a string")),
  deadline: nullable(
    string("Field is not ISODateString", [regex(isoDateStringRegex)])
  ),
  status: picklist(["todo", "inProgress", "done"], "Invalid status"),
  createdAt: string([regex(isoDateStringRegex)]),
  updatedAt: string([regex(isoDateStringRegex)]),
});

export interface FixedJsonServerRouter<T> extends JsonServerRouter<DB> {
  render: (req: Request, res: Response) => void;
}

const server = JsonServer.create();
const router = JsonServer.router<DB>("db.json");
const fixedRouter = router as FixedJsonServerRouter<LowdbSync<DB>>;

fixedRouter.render = (req, res) => {
  const [, params] = req.url.split("?");
  const urlSearchParams = new URLSearchParams(params);

  if (req.path === "/todos" && req.method === "GET") {
    const totalCount =
      // @ts-ignore
      res.getHeader("X-Total-Count")?.value() ||
      fixedRouter.db.get("todos").value().length;
    const limit = parseInt(urlSearchParams.get("_limit") || totalCount);
    const pageCount = Math.ceil(totalCount / limit);

    res.jsonp({
      success: true,
      data: res.locals.data,
      totalCount,
      pageCount,
    });
  } else {
    res.jsonp({
      success: true,
      data: res.locals.data,
    });
  }
};

// /tagsのGET
server.get("/tags", (req, res) => {
  const todos = fixedRouter.db.get("todos");
  const tags = Array.from(new Set(todos.value().flatMap((todo) => todo.tags)));
  // todosを削除して0件になったときの動作
  res.jsonp({
    success: true,
    data: tags.map((tag) => ({ name: tag })),
  });
});

type Statuses = Record<
  Status,
  {
    name: string;
    label: string;
    totalCount: number;
  }
>;

server.get("/statuses", (req, res) => {
  const todos = fixedRouter.db.get("todos").value();
  const statuses: Statuses = {
    todo: {
      name: "todo",
      label: "Todo",
      totalCount: todos.filter((todo) => todo.status === "todo").length,
    },
    inProgress: {
      name: "inProgress",
      label: "In Progress",
      totalCount: todos.filter((todo) => todo.status === "inProgress").length,
    },
    done: {
      name: "done",
      label: "Done",
      totalCount: todos.filter((todo) => todo.status === "done").length,
    },
  };
  res.jsonp({
    success: true,
    data: statuses,
  });
});

server.use(JsonServer.bodyParser);
server.use((req, res, next) => {
  const [, params] = req.url.split("?");

  if (req.path === "/todos" && req.method === "GET") {
    req.query._sort = "id";
    req.query._order = "desc";
  }

  // todosのPOST時にcreatedAtとupdatedAtを追加する
  if (req.path === "/todos" && req.method === "POST") {
    req.body.createdAt = new Date().toISOString();
    req.body.updatedAt = new Date().toISOString();
  }

  // todosのPUT時に不足プロパティを追加&バリデーションを行う
  if (/^\/todos\/(\d+)$/.test(req.path) && req.method === "PUT") {
    const id = req.path.split("/").pop() || req.body.id;
    const todo = fixedRouter.db
      .get("todos")
      .find({ id: parseInt(id, 10) })
      .value();
    if (todo) {
      req.body = {
        ...todo,
        ...req.body,
        updatedAt: new Date().toISOString(),
      };
    }
    try {
      parse(TodoSchema, req.body);
    } catch (errors) {
      if (errors instanceof ValiError) {
        console.log("validation error");
        res.jsonp({
          success: false,
          errors: transformFromValiErrorToErrorMessage(errors),
        });
      }
      return;
    }
  }

  // todosのPOST時のバリデーションをvalibotで行う
  if (req.path === "/todos" && req.method === "POST") {
    try {
      parse(TodoSchema, req.body);
    } catch (errors) {
      if (errors instanceof ValiError) {
        console.log("validation error");
        res.jsonp({
          success: false,
          errors: transformFromValiErrorToErrorMessage(errors),
        });
      }
      return;
    }
  }
  // Continue to JSON Server router
  next();
});

const middlewares = JsonServer.defaults();

server.use(middlewares);
server.use(fixedRouter);

server.listen(5000, () => {
  console.log("JSON Server is running: http://localhost:5000");
});

function transformFromValiErrorToErrorMessage(error: ValiError) {
  return error.issues.map(({ message, path }) => {
    return {
      message,
      key: path?.[0].key,
      value: path?.[0]?.value,
    };
  });
}
