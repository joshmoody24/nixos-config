# Josh Moody Code Style Guide

When writing in this codebase, here are guidelines for writing code that Josh Moody (the active developer) is most likely to approve.

## Comments

Write few comments. Code should be self-documenting through good naming. Only comment to explain _why_ something non-obvious is done, never _what_ the code does. Do not narrate or restate logic that is clear from reading the code. Prefer no comment over a redundant one. Keep any comment you do write short. A helpful analogy is that comments should be in "third normal form" in a sense: any given fact should exist exactly once in the code. If a comment would need to be updated for every code change, then it's not sufficiently normalized.

## Favor Immutability

Mutable variables are harder to reason about. When tempted to use `let`, find a way to use `const` instead. For example:

```typescript
// bad example
let result: int | null = null;

try {
  result = foo();
} catch {
  console.error("Failed to foo");
}
```

The code above can be improved as follows:

```typescript
// good example
const result = (() => {
  try {
    return foo();
  } catch {
    console.error("Failed to foo");
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

Avoid duplicating large quantities of code. If you notice yourself having written very similar code in more than one place, please proactively de-duplicate. This also applies to pre-existing code. If you are solving a problem that seems suspiciously general-purpose, assume it has already been solved and look for an existing utils before implementing your own.

## Complexity

I care a LOT about understanding what code does, and why. Working code is not sufficient by itself, and often the first iteration is not the best one. It's worth extra thinking up front to ensure that what you build is simple, extensible, discoverable, and maintainable.

Specifically, use the following two definitions of complexity:

- Rich Hickey: complexity is multiple concepts woven together.
- John Ousterhout: complexity is anything about the structure of a software system that makes it hard to understand and modify.

Avoid unknown unknowns, AKA hidden coupling. When two systems are genuinely coupled, they should be bidirectionally discoverable, and it should not be possible to change one without being forced to change the other as well. Tests and type checking are good ways to enforce constraints.

But the even better solution is to decouple things. When possible, favor small, composable systems rather than bespoke ones. Often (and counterintuitively), general tools are simpler than specialized ones.

Favor deep modules with simple interfaces. Make decisions once, and then encapsulate that decision in a module ("information hiding").

Write your code assuming that I am busy and tired and want to be able to instantly grok the intent and behavior without deeply understanding the code. In other words, the code should be straightforward and concise, with the code itself explaining clearly what happens, with natural language comments only explaining things the code itself isn't aware of, like external constraints or why the system was designed a certain way.

Avoid building exactly what I asked you if it feels unnecessarily complex. Hammock-driven development will help us come to the right solution together.

## Fast Iteration

Look for ways to test code immediately. The faster the verification loop the better.

An example of a bad approach would be type checking an entire heavy codebase after every minor change. If a given validation job is expensive, do it as late as is reasonable. On the other hand, a cheap validation job should be run freqeuently.

Reviewing large changes all at once is hard. Favor incremental code changes that can each be independently reviewed.

## Communication Style

Large language models are infamous for using overly dense, formal writing styles riddled with jargon. Avoid this at all costs, because I will tell you to dumb it down for me. Talk in a plain, concise, down-to-earth style. Use simple words that even an idiot engineer would understand.
