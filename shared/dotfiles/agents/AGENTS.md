# Josh Moody Code Style Guide

When writing in this codebase, here are guidelines for writing code that Josh Moody (the active developer) is most likely to approve.

## Favor Immutability

Mutable variables are harder to reason about. When tempted to use `let`, find a way to use `const` instead. For example:

```typescript
// bad example
let result: int | null = null;

try {
  result = foo();
} catch {
  console.error("Failed to foo")
}
```

The code above can be improved as follows:

```typescript
// good example
const result = (() => {
  try {
    return foo();
  } catch {
    console.error("Failed to foo")
    return null;
  }
})();
```

This reduces the cognitive load required to understand the code's behavior.

## Descriptive Log Messages

Log messages should always have the most important dynamic information directly in the log message, not the additional context object. For example:

```typescript
// bad example
logger.exception(`Failed to foo`, e, {
  teamId: team._id,
});
```

```typescript
// good example
const teamId = team._id;
logger.exception(`Failed to foo for team ${teamId}`, e, {
  teamId,
});
```

## Confidence Level

In general, I prefer to have a high level of control and understanding over code produced by Claude. This means:

- When debugging, I prefer Claude to avoid jumping to conclusions. Approach issues with a scientific mindset with hypotheses. Mutually Exclusive / Collectively Exhaustive is a good mindset.
- When planning, err on the side of asking too many design questions than too few. I prefer to have control over ambiguous aspects of initial requests.
- When debugging, rather than jump to conclusions for difficult issues, it can be helpful to ponder "what additional information are we missing that would make finding the root cause trivial?" This is often additional logging. Rather than wild guessing at the root cause when unsure, favor the scientific method.

## React Hooks

This advice only applies to projects that use React or similar frameworks.

Avoid loading data with the classic `useState` and `useEffect` combo. Favor custom hooks like `useLoad`, `useTriggerLoad`, `useRpcQuery`, etc., whenever possible. Examine the specific repository for what already exists.

## State

State is the cause of many bugs. Whenever possible, look for ways to derive state from the purest possible data model. This applies to the frontend (minimize `useState` and `useRef`) and the backend (minimize derived values in the database).

## Declarative vs Imperative

In general, favor a declarative approach to code that looks more like functional or logic programming. However, imperative code is not entirely useless. Be judicious when deciding an approach. Business logic is typically best expressed in a declarative manner.

## Code Duplication

Avoid duplicating large quantities of code. If you notice yourself having written very similar code in more than one place, please proactively de-duplicate. This also applies to pre-existing code. Many problems in this codebase have been solved before. Look for existing utility functions before implementing your own.

## Running Unit and Integration Tests

`--test-filter` only supports substrings from the file path, not individual test names.

## Fast Iteration

Look for ways to run a node or bazel repl to test code immediately. The faster the verification loop the better.

Avoid type checking packages downstream of `redo/server`, because the build times are too long for the benefit to be worthwhile. Similarly, avoid building packages in general due to the lack of value. Reasoning from first principles about correctness and writing tests is the most useful way to ensure correctness. Type checking packages before `server` like `redo/model` is acceptable if done judiciously.
