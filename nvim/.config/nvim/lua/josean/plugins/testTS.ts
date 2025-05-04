// Define the MarkdownPost type
type MarkdownPost = {
  title: string;
  slug: string;
  date: Date;
  content: string;
  tags?: string[]; // Optional array of tags
  author: string;
};

// Example usage of the MarkdownPost type
const myPost: MarkdownPost = {
  title: "My First Markdown Post",
  slug: "my-first-post",
  date: new Date("2025-05-04"),
  content: "# This is the content of my first post.",
  tags: ["typescript", "markdown", "example"],
  author: "Aditya",
};

console.log(myPost.title);
console.log(myPost.tags?.[0]); // Accessing an optional property safely

// You can also try creating an object without the 'tags' property
const anotherPost: MarkdownPost = {
  title: "Another Post",
  slug: "another-post",
  date: new Date("2025-05-05"),
  content: "More content here.",
  author: "Aditya",
};

console.log(anotherPost.slug);

// Define a simple interface
interface Person {
  name: string;
  age: number;
}

// Create a function that greets a person
function greet(person: Person): string {
  return `Hello, ${person.name}! You are ${person.age} years old.`;
}

// Create an object implementing the Person interface
const user: Person = { name: "Aditya", age: 30 };

// Call the greet function and log the result
console.log(greet(user));
