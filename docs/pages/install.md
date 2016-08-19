---
title: Installation
layout: page
permalink: /install/
order: 2
---

If you are using `dub` add following dependency to your `dub.json` or `dub.sdl` file.


### Latest version (`2.0`)

> __NOTE__: This version is backwards API compatible, if you have any compatibility issues, __please__ report them.

New version which features new parser, supports multiline strings and more.
Although it is backwards compatible, some smaller issues may occur as it is not completly stable yet.

{% highlight js %}
"dependencies": {
    "dini": "~> 2.0.0-rc"
}
{% endhighlight %}

{% highlight sdl %}
dependency "dini" version="~> 2.0.0-rc"
{% endhighlight %}


### Stable version (`1.1`)

If you don't need features of latest version or prefer more stable solution.

> __NOTE__: This documentation is targeted for version `2.0`. Some of the documented featured may not be available.

{% highlight js %}
"dependencies": {
    "dini": "~> 1.0.1"
}
{% endhighlight %}

{% highlight sdl %}
dependency "dini" version="~> 1.0.1"
{% endhighlight %}