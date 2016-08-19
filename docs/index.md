---
layout: page
title: Home
permalink: /
order: 1
---

`dini` is a library written in [D Programming Language](http://www.dlang.org/)
that allows you to read and write `INI` files.

### Why `ini`?

INI is widely popular, lightweight key-value text configuration format. While being very simple to learn and edit
manually it is also very fast to parse.

In contrast to `JSON`, which is also commonly used for configuration purposes, `ini` allows to embed comments, while `JSON`
does not. And as for `YAML`, `ini` is much more lightweight and simpler. It looks roughly like this:

{% highlight ini %}
[section name]
key = value

; comments are allowed on dedicated lines
another key = "another value"

[section 2]
key = section 2 value
{% endhighlight%}


### Features

 - __Easy to use__

     API is fairy simple and straightforward and allows you to lower-level to get more control.

 - __Rich support__

     `dini` supports features such as section inheritance or variable lookups.

 - __Configurable__ (`>= 2.0.0`)

    Since `v2.0` you can define custom quotes, comments and use custom type to store values.

    Also, if you don't like current model tree, you can write your own eaisly using `INIReader`.
