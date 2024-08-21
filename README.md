# About

This is the content of Salix on gemini. It includes most stuff from the main
website, as well as the blog and documentation.

The main website is written directly in gemfiles for gemini. The blog and
documentation are auto-generated from the respective
[blog.salixos.org](blog.salixos.org) and [docs.salixos.org](docs.salixos.org)
sites.

Every time a new post/edited content appears in the blog or docs, to update
the gemini content, you must respectively run:

```
make update-posts
```

or:

```
make update-docs
```

The blog and docs repos should be at the same level as this repo, see the
first few lines of the Makefile. I know, the "proper" way to do that would
be with git submodules, but I was bored and it works fine this way.

