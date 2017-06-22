
## Management Center Reference Manual Using Daux

Daux.io is a documentation generator that uses a simple folder structure and Markdown files to create custom documentation on the fly. It helps you create great looking documentation in a developer friendly way.

Please refer to [Daux.io](http://daux.io/) for more information.


## Prerequisites

Before installing Daux, you already need to have the following:

- PHP 5.5 or higher = http://php.net/
- Composer: https://getcomposer.org/ (Install and then add "~/.composer/vendor/bin” to your $PATH)

## Installing dependencies

- `composer install` to install the required dependencies to build the project

## Where Are the Source MarkDown Files

They reside in the **docs** folder of this repo structured with folders and MarkDown files.

## Writing Content

Now you can clone this repo and start writing with MarkDown.

## Building the HTML

Simply run the command `bin/daux` or `generate` in the root folder.

## Viewing in Browser

To view the generated HTML in the browser, use the `serve` command and browse
to the reported URL on your browser. 

## Where Is the Generated HTML

Each time you build the Management Center Manual, its HTML output will be put into the **static** folder of this repo. Build process creates this folder automatically if it does not exist.
