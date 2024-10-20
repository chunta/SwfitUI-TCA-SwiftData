# API Server

This document explains how to run API server and API endpoints.

## Prerequisites

- Node.js: 20.6.x or higher

## How to run
- Run `npm ci` to fetch the dependencies
- Run `npm start` to start the server
- The server runs on http://localhost:5000 

## API endpoints

### `/todos`

```shell
# GET
curl http://localhost:5000/todos
# paginate
curl 'http://localhost:5173/api/todos?_page=1&_limit=10'
# filter status and tag
curl 'http://localhost:5173/api/todos?status=todo&tags_like=travel'
# full text search
curl 'http://localhost:5173/api/todos?q=Book'

# POST
curl -H "Content-Type: application/json" -d '{
      "title": "title",
      "tags": ["tag1", "tag2"],
      "deadline": "2023-12-14T12:34:56.789+05:30",
      "status": "todo"
    }' -X POST http://localhost:5000/todos

# POST: Validation Error of Required
curl -H "Content-Type: application/json" -d '{
      "tags": ["tag1", "tag2"],
      "deadline": "2023-12-14T12:34:56.789+05:30",
      "status": "todo"
    }' -X POST http://localhost:5000/todos

# POST: Validation Error of Required
curl -H "Content-Type: application/json" -d '{
      "tags": ["tag1", "tag2"],
      "deadline": "2023-12-14T12:34:56.789+05:30",
      "status": "todo"
    }' -X POST http://localhost:5000/todos

# POST: Validation Error of ISODateString
curl -H "Content-Type: application/json" -d '{
      "title": "title",
      "tags": ["tag1", "tag2"],
      "deadline": "invalid-date-type",
      "status": "todo"
    }' -X POST http://localhost:5000/todos

# POST: Validation Error of Status
curl -H "Content-Type: application/json" -d '{
      "title": "title",
      "tags": ["tag1", "tag2"],
      "deadline": "2023-12-14T12:34:56.789+05:30",
      "status": "invalid-status"
    }' -X POST http://localhost:5000/todos

# POST: Validation Error of Tags
curl -H "Content-Type: application/json" -d '{
      "title": "title",
      "tags": "invalid-tags-type",
      "deadline": "2023-12-14T12:34:56.789+05:30",
      "status": "todo"
    }' -X POST http://localhost:5000/todos
```

### `/todos/:id`

```shell
# GET
curl http://localhost:5000/todos/{:id}

# PUT
curl -H "Content-Type: application/json" -d '{
      "deadline": "2023-12-14T06:42:51.313Z"
    }' -X PUT http://localhost:5000/todos/{:id}

# DELETE
curl -H "Content-Type: application/json" -X DELETE http://localhost:5000/todos/{:id}
```

### `/tasks`

```shell
# GET
curl http://localhost:5000/tags
```

### `/statuses`

```shell
# GET
curl http://localhost:5000/statuses
```
