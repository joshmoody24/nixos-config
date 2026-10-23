---
name: review-complexity
description: Review a system to ensure it is simple, understandable, extensible, and maintainable. Use when asked to review complexity, simplify a change, or judge whether an abstraction is carrying its weight.
---

When reviewing a system, please use Rich Hickey as your primary role model. Some of the most important principles include simple versus easy, the value of values, and hammock-driven development.

Here are some examples of complex things, and the simple alternative:

- State, Variables -> Values
- Objects, Methods -> Functions, Namespaces
- Syntax -> Data
- Inheritance -> Polymorphism a la carte
- Graphs -> Sets
- Imperative loops, fold -> Declarative data manipulation
- Actors -> Queues

The second most valuable role model is John Ousterhout. He has a different definition of complexity than Rich Hickey, but an equally valuable one. Identify any violations of his principles in A Philosophy of Software Design, and find solutions to make the system simple. Especially look for unknown unknowns, shallow modules, overly specialized code, and tactical programming.

Also use Carson Gross as a role model, particularly his ideas in the Grug Brained Developer.

Review the system from the perspective of each role model above. Start by finding weaknesses in the system's design. Don't jump right to proposing solutions. First, revisit the problem from first principles. Revisit core assumptions. Perhaps the original ask was framed oddly, and there was a simpler solution hiding in plain sight the whole time. Or maybe the core was already good and we just need to tidy up the boundaries of the system. After putting in the deep thinking time necessary, propose solutions.

Sometimes complexity is a necessary evil. Performance optimization is a good example. In cases like this, ensure the complexity is contained. Containing complexity is almost as good as eliminating it. But there should always be a clean layer to the system. Focus first on getting the correct solution, then add the needed complexity to it as needed. There should always be a layer of the system that is extremely easy to understand. As in, code that reads almost like plain English, and the complexity is encapsulated underneath.

Consider the definition of words carefully while thinking about a problem. Often, complexity comes from a word's meaning being incorrect or conflated.

When proposing solutions, consider the irony of your explanation being complex. If your solutions aren't explainable to a literal five year old, it probably isn't truly simple. The way you articulate the solution should be plain and simple. Avoid technical jargon, but also use words precisely. If there's a well-defined word that software engineers understand, use that, and use it consistently. Don't change the term you use just to make the writing more natural. Technical writing benefits from precise words.

Proceed with the analysis.
