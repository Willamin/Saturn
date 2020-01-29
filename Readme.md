# Saturn

see the `sample.saturn` for an explanation.

also you can transpile it into markdown via `ruby saturn.rb < sample.saturn`. 
additionally, you can use pandoc to transpile a saturn file into an html document (styled and everything!) with:
```
$ ruby saturn.rb < sample.saturn           \
  | pandoc -f gfm                          \
           -t html                         \
           --metadata title=titleName      \
           --template=saturn               \
  > output.html
```
