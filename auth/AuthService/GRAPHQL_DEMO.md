# GraphQL API Demo for AuthService

## Overview

This document demonstrates the GraphQL API implementation for the AuthService microservice, showcasing the advantages of GraphQL over traditional REST APIs.

## GraphQL Endpoint

- **URL**: `http://localhost:5000/graphql`
- **Method**: POST
- **Content-Type**: `application/json`

## Build Notes

The implementation uses HotChocolate v14.0.0 which includes breaking changes from v13:
- `AddProjections()` method has been removed (projections are now enabled by default)
- `AddFiltering()` and `AddSorting()` methods moved to separate packages (not needed for basic implementation)
- Updated package versions to resolve compatibility issues
- Fixed nullable reference warnings for better code quality
- Added explicit `[GraphQLName]` attributes to prevent type registration conflicts
- Simplified GraphQL configuration to use auto-discovery instead of manual type registration

## GraphQL Advantages Demonstrated

### 1. Flexible Field Selection

GraphQL allows clients to request only the fields they need, reducing over-fetching and improving performance.

#### Example 1: Request only Access Token
```graphql
mutation {
  authenticate(input: {
    userName: "john_doe"
    password: "password123"
  }) {
    accessToken
    success
  }
}
```

**Response:**
```json
{
  "data": {
    "authenticate": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "success": true
    }
  }
}
```

#### Example 2: Request both tokens with user info
```graphql
mutation {
  authenticate(input: {
    userName: "john_doe"
    password: "password123"
  }) {
    accessToken
    refreshToken
    userId
    role
    success
  }
}
```

**Response:**
```json
{
  "data": {
    "authenticate": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "userId": "user123",
      "role": "admin",
      "success": true
    }
  }
}
```

### 2. Single Query for Multiple Operations

GraphQL allows batching multiple operations in a single request, reducing network round trips.

#### Example: Batch Authentication and User Identification
```graphql
mutation {
  auth: authenticate(input: {
    userName: "john_doe"
    password: "password123"
  }) {
    accessToken
    userId
    role
    success
  }
  
  identify: identify(input: {
    accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    requiredRoles: ["admin", "user"]
  }) {
    userId
    role
    isValid
  }
}
```

**Response:**
```json
{
  "data": {
    "auth": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "userId": "user123",
      "role": "admin",
      "success": true
    },
    "identify": {
      "userId": "user123",
      "role": "admin",
      "isValid": true
    }
  }
}
```

### 3. Strong Typing and Schema Introspection

GraphQL provides a self-documenting API with strong typing and schema introspection.

#### Schema Introspection Query
```graphql
query {
  __schema {
    types {
      name
      description
      fields {
        name
        type {
          name
        }
      }
    }
  }
}
```

#### Type Information Query
```graphql
query {
  __type(name: "AuthPayloadType") {
    name
    description
    fields {
      name
      description
      type {
        name
        kind
      }
    }
  }
}
```

## Complete API Examples

### Authentication Flow

#### 1. Login
```graphql
mutation Login($input: LoginInput!) {
  authenticate(input: $input) {
    accessToken
    refreshToken
    userId
    role
    success
    errorMessage
  }
}
```

**Variables:**
```json
{
  "input": {
    "userName": "john_doe",
    "password": "password123"
  }
}
```

#### 2. Token Refresh
```graphql
mutation RefreshToken($input: RefreshTokenInput!) {
  refresh(input: $input) {
    accessToken
    refreshToken
    userId
    role
    success
    errorMessage
  }
}
```

**Variables:**
```json
{
  "input": {
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 3. User Identification
```graphql
query IdentifyUser($input: IdentifyInput!) {
  identify(input: $input) {
    userId
    role
    isValid
    errorMessage
  }
}
```

**Variables:**
```json
{
  "input": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "requiredRoles": ["admin"]
  }
}
```

#### 4. Logout
```graphql
mutation Logout($input: LogoutInput!) {
  logout(input: $input) {
    success
    errorMessage
  }
}
```

**Variables:**
```json
{
  "input": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## Comparison: REST vs GraphQL

### REST API Calls (3 separate requests)
```bash
# 1. Login
POST /auth
{
  "userName": "john_doe",
  "password": "password123"
}

# 2. Identify user
POST /auth/identify
{
  "accessToken": "...",
  "role": ["admin"]
}

# 3. Get user details (if needed)
GET /users/user123
```

### GraphQL (1 single request)
```graphql
mutation {
  authenticate(input: {
    userName: "john_doe"
    password: "password123"
  }) {
    accessToken
    userId
    role
  }
  
  identify(input: {
    accessToken: "..."
    requiredRoles: ["admin"]
  }) {
    userId
    role
    isValid
  }
}
```

## Benefits Demonstrated

1. **Reduced Network Overhead**: Single request instead of multiple REST calls
2. **Flexible Data Fetching**: Request only needed fields
3. **Type Safety**: Strong typing prevents runtime errors
4. **Self-Documenting**: Schema introspection provides API documentation
5. **Versioning**: No need for API versioning - schema evolution handles changes
6. **Developer Experience**: Single endpoint with rich tooling support

## Error Handling

GraphQL provides structured error responses:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Invalid credentials",
      "locations": [
        {
          "line": 2,
          "column": 3
        }
      ],
      "path": [
        "authenticate"
      ]
    }
  ]
}
```

## Testing the API

### Using curl
```bash
curl -X POST http://localhost:5000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { authenticate(input: { userName: \"test\", password: \"test\" }) { success accessToken } }"
  }'
```

### Using GraphQL Playground
Visit `http://localhost:5000/graphql` in your browser to access the GraphQL playground for interactive testing.

## Schema Definition

The complete GraphQL schema includes:

- **Queries**: `identify` - Verify and get user information from token
- **Mutations**: `authenticate`, `refresh`, `logout` - Authentication operations
- **Types**: `AuthPayloadType`, `UserInfoType`, `TokenType` - Response types
- **Inputs**: `LoginInput`, `RefreshTokenInput`, `IdentifyInput`, `LogoutInput` - Input types

This implementation demonstrates how GraphQL can provide a more flexible, efficient, and developer-friendly alternative to REST APIs while maintaining the same functionality.
