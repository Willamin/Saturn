.DEFAULT_GOAL := all

.PHONY: readme
readme:
	ruby saturn.rb < readme.saturn > readme.md

.PHONY: index
index:
	ruby saturn.rb < readme.saturn | pandoc -f gfm -t html --metadata title=titleName --template=saturn > docs/index.html

.PHONE: all
all: readme index
