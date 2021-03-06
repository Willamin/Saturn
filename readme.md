# Saturn

Saturn is a tool to manage data, information, and actionable code in one place.
Each note consists of a single text file which contains markdown-like literate Ruby (language subject to change).
A standard Saturn Code Block is denoted by lines containing only `% ruby` and `% end`.

```
greeting = "hello"
glue = ", "
name = "world"
puts(greeting + glue + name)
```
hello, world


Standard Saturn Code Blocks display their contents the same way a markdown code fence does.
Any `$stdout` that the code generates is displayed directly afterwards as if it was the markdown-like part of the file.

In the event that some code may be awkwardly long (eg. data) abbreviated Saturn Code Blocks can be denoted by lines containing only `% hidden ruby` and `% end`.




To allow for more composable documents, the ruby blocks (standard and hidden) are executed as if they were concatenated.
The separation throughout the document only serves the purpose of determining where `$stdout` is displayed in the output view.



here's some data from a previous cell:
- foo
- bar
- baz


To recreate this Saturn file, you can run the following code snippet, which transforms the Saturn file to markdown, then uses pandoc (and an html template) to generate html. 
```
$ ruby saturn.rb < readme.saturn           \
  | pandoc -f gfm                          \
           -t html                         \
           --metadata title=titleName      \
           --template=saturn               \
  > docs/index.html
```

Or as a quick readme:
```
$ ruby saturn.rb  \
  < readme.saturn \
  > readme.md
```






