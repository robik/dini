---
layout: page
title: Format compatibility
permalink: /compatibility/
order: 3
---

*This page describes various INI format similarities and differences and how `dini` handles them.*

Due to lack of any official specification many variations have been created.
Unless you have to, you should write ini that is most compatible (greatest common divisor).


### Similarities

Elements that are most commonly used and are free to use:

  - Sections denoted with square brackets `[section]`
    
    > **`dini`**: Section names are whitespace trimmed
  
  - Equals as key delimeter (`=`): `key = value`
    
    > **`dini`**: Key names are trimmed and values are left-trimmed
    
  - Comments are denoted with semicolon (`;`) and are allowed only on dedicated lines:
    
    ```INI
    ; comment line
    key = value ; this is part of value
    ```


### Differences

Here's a list of things that vary between parsers:

  - Colon as key delimeter

    Currently not supported. This one is pretty rare and such configuration files should be called `ini` anymore.

  - Hashes for comments

    Supported, but can be disabled. This one is pretty common and not so intrusive.

  - Multiline strings

    Supported, but can be disabled. Allows you to define values as such:

    ```INI
    key="""
        multiline value
    """
    ```

  - Quoted keys

    Supported. Quoted keys are used by Windows Registry export.

  - Escape sequences

    Supported, but can be disabled.

  - Escaped line feeds

    Supported. You can escape new lines in values to ignore them. For example:

    ```INI
    # the value below does not contain newline!
    name=this is a very \
     long value
    ```

